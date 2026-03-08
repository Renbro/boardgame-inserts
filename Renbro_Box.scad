/* --- HOW TO USE THIS GRID ---
   grid_rows is a list of your rows from Top to Bottom.
   Each row contains: [[Widths of Wells], Length of Row]
   
   Example: [[10, 20, 10], 30] 
   - This creates 3 wells with widths of 10, 20, and 10.
   - The entire row will be 30mm deep (Y-axis).
   - The script automatically adds wall_thickness between everything.
*/

// --- User Defined Grid ---
grid_rows = [
    [[34.2, 35, 13.8], 30],
    [[40, 44.2], 20]
];

well_height = 15;
wall_thickness = 1.2; 

// --- Smoothing Settings ---
scoop_radius = 4;      
outer_rounding = 0.3;  
curve_smoothness = 32; 

// --- Helper Functions ---
function clean(n) = round(n * 1000) / 1000;

function sum_w(row_idx, n) = 
    (n <= 0) ? 0 : grid_rows[row_idx][0][n-1] + wall_thickness + sum_w(row_idx, n-1);

function sum_l(n) = 
    (n <= 0) ? 0 : grid_rows[n-1][1] + wall_thickness + sum_l(n-1);

// --- Calculations ---
num_rows = len(grid_rows);
total_y = sum_l(num_rows) + wall_thickness;

row_widths = [for (r = [0:num_rows-1]) sum_w(r, len(grid_rows[r][0])) + wall_thickness];
total_x = max(row_widths);
total_z = well_height + wall_thickness;

// Check if any gaps exist across all rows
has_any_gap = len([for (w = row_widths) if (abs(total_x - w) > 0.0001) w]) > 0;

// --- Spaced Console Echoes ---
echo("========================================");
echo(""); 
echo(str("TOTAL BOX SIZE: X=", clean(total_x), "mm, Y=", clean(total_y), "mm, Z=", clean(total_z), "mm"));
echo(""); 

if (!has_any_gap) {
    echo("No Gaps!");
} else {
    echo("Gaps:");
    for (r = [0 : num_rows - 1]) {
        row_w = row_widths[r];
        gap = total_x - row_w;
        gap_text = (abs(gap) > 0.0001) ? str(" - ", clean(gap), "mm") : "";
        echo(str("ROW ", r + 1, gap_text));
    }
}

echo(""); 
echo("========================================");

// --- The Construction ---
difference() {
    // 1. Fully Rounded Outer Shell
    hull() {
        r = outer_rounding;
        for(x = [r, total_x - r], y = [r, total_y - r]) {
            translate([x, y, r]) 
                sphere(r, $fn = curve_smoothness);
            translate([x, y, total_z - r]) 
                sphere(r, $fn = curve_smoothness);
        }
    }

    // 2. Internal Scooped Wells
    for (r_idx = [0 : num_rows - 1]) {
        row_widths_list = grid_rows[r_idx][0];
        l = grid_rows[r_idx][1];
        
        y_row_top_edge = total_y - (sum_l(r_idx) + wall_thickness);
        y_offset = y_row_top_edge - l;
        
        for (c_idx = [0 : len(row_widths_list) - 1]) {
            w = row_widths_list[c_idx];
            x_offset = sum_w(r_idx, c_idx) + wall_thickness;
            
            translate([x_offset, y_offset, wall_thickness])
                scooped_well(w, l, well_height + 1, scoop_radius);
        }
    }
}

// Module for the Inner Scooped Wells
module scooped_well(w, l, h, r) {
    hull() {
        translate([0, 0, r]) cube([w, l, h - r]);
        for(x = [r, w - r], y = [r, l - r])
            translate([x, y, r]) sphere(r, $fn = curve_smoothness);
    }
}