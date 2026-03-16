/* ============================================================
   I. USER DEFINED GRID 
   ============================================================ */
// Define the internal layout of the box.
// grid_rows: A list of rows. Each row contains [List of Widths, Row Depth].
grid_rows = [
    [[34.2, 35, 13.8], 30],
    [[40, 44.2], 20]
];

well_height = 15;    // Internal depth of the wells (not including floor)
wall_thickness = 1.2; // Thickness of the outer and internal divider walls


/* ============================================================
   II. SHAPE SETTINGS 
   ============================================================ */
scoop_radius = 4;        // Radius of the "scooped" curve at the bottom of wells
corner_radius = 0.5;      // Outer corner rounding for the entire box
curve_smoothness = 32;   // Level of detail for all curves ($fn)


/* ============================================================
   III. SIDE CUTOUTS & FINGER NOTCHES
   ============================================================ */
// DESIGN NOTE: These cutouts are ideal for "One-Big-Well" setups (like card boxes) 
// to allow easy finger access. If using a grid with many internal walls, 
// these notches may be blocked by those walls, making them less functional.

default_cutout_radius = 4; // Rounding for the notch "shoulders" and bottom

// ARRAY FORMAT: [Width, Depth_From_Top, Notch_Corner_Radius, Vertical_Cylinder_Diameter]
// 1. Width: Total span of the cutout along the wall. (0 to disable)
// 2. Depth_From_Top: How far down the notch eats into the side wall.
// 3. Notch_Corner_Radius: Rounding for the cutout corners.
// 4. Vertical_Cylinder_Diameter: Size of the floor-to-top thumb hole. (0 to disable)

cutout_front  = [20, 10, default_cutout_radius, 0]; 
cutout_back   = [20, 10, default_cutout_radius, 0];
cutout_left   = [15, 8,  default_cutout_radius, 0];
cutout_right  = [15, 8,  default_cutout_radius, 16]; 


/* ============================================================
   IV. CALCULATIONS & GEOMETRY (Internal Logic)
   ============================================================ */
function sum_w(row_idx, n) = (n <= 0) ? 0 : grid_rows[row_idx][0][n-1] + wall_thickness + sum_w(row_idx, n-1);
function sum_l(n) = (n <= 0) ? 0 : grid_rows[n-1][1] + wall_thickness + sum_l(n-1);

num_rows = len(grid_rows);
total_y = sum_l(num_rows) + wall_thickness;
row_widths = [for (r = [0:num_rows-1]) sum_w(r, len(grid_rows[r][0])) + wall_thickness];
total_x = max(row_widths);
total_z = well_height + wall_thickness;

/* --- Main Difference Block --- */
difference() {
    // 1. Outer Shell
    if (corner_radius <= 0.01) {
        cube([total_x, total_y, total_z]);
    } else {
        hull() {
            for(x = [corner_radius, total_x - corner_radius], y = [corner_radius, total_y - corner_radius]) {
                translate([x, y, 0]) 
                    cylinder(r = corner_radius, h = total_z, $fn = curve_smoothness);
            }
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
            
            if (corner_radius > wall_thickness + 0.1) {
                intersection() {
                    translate([x_offset, y_offset, wall_thickness])
                        scooped_well(w, l, well_height + 1, scoop_radius, curve_smoothness); 
                    
                    translate([0,0,-1])
                    hull() {
                        for(x = [corner_radius, total_x - corner_radius], y = [corner_radius, total_y - corner_radius]) {
                            translate([x, y, 0]) 
                                cylinder(r = corner_radius - wall_thickness, h = total_z + 2, $fn = curve_smoothness);
                        }
                    }
                }
            } else {
                translate([x_offset, y_offset, wall_thickness])
                    scooped_well(w, l, well_height + 1, scoop_radius, curve_smoothness);
            }
        }
    }

    // 3. Side Wall Notches (Constrained to wall thickness)
    cut_d = wall_thickness + 0.2;

    if(cutout_front[0] > 0)
        translate([total_x/2 - cutout_front[0]/2, -0.1, total_z - cutout_front[1]])
            rounded_cutout(cutout_front[0], cut_d, cutout_front[1], cutout_front[2], curve_smoothness);
    
    if(cutout_back[0] > 0)
        translate([total_x/2 - cutout_back[0]/2, total_y - wall_thickness - 0.1, total_z - cutout_back[1]])
            rounded_cutout(cutout_back[0], cut_d, cutout_back[1], cutout_back[2], curve_smoothness);

    if(cutout_left[0] > 0)
        translate([-0.1, total_y/2 - cutout_left[0]/2, total_z - cutout_left[1]])
            rotate([0,0,90]) translate([0, -cut_d, 0])
                rounded_cutout(cutout_left[0], cut_d, cutout_left[1], cutout_left[2], curve_smoothness);

    if(cutout_right[0] > 0)
        translate([total_x - wall_thickness - 0.1, total_y/2 - cutout_right[0]/2, total_z - cutout_right[1]])
            rotate([0,0,90]) translate([0, -cut_d, 0])
                rounded_cutout(cutout_right[0], cut_d, cutout_right[1], cutout_right[2], curve_smoothness);

    // 4. Vertical Finger-Hole Cylinders (Cuts into the floor/wells)
    if(cutout_front[3] > 0)
        translate([total_x/2, wall_thickness/2, -1])
            cylinder(d = cutout_front[3], h = total_z + 2, $fn = curve_smoothness);

    if(cutout_back[3] > 0)
        translate([total_x/2, total_y - wall_thickness/2, -1])
            cylinder(d = cutout_back[3], h = total_z + 2, $fn = curve_smoothness);

    if(cutout_left[3] > 0)
        translate([wall_thickness/2, total_y/2, -1])
            cylinder(d = cutout_left[3], h = total_z + 2, $fn = curve_smoothness);

    if(cutout_right[3] > 0)
        translate([total_x - wall_thickness/2, total_y/2, -1])
            cylinder(d = cutout_right[3], h = total_z + 2, $fn = curve_smoothness);
}


/* ============================================================
   V. MODULES 
   ============================================================ */

// Creates the rounded rectangle cutout for the side walls
module rounded_cutout(w, d, h, r, fn_val) {
    safe_r = min(r, w/2 - 0.1, h/2 - 0.1); 
    hull() {
        for(x = [safe_r, w - safe_r], z = [safe_r, h + safe_r]) 
            translate([x, 0, z])
                rotate([-90, 0, 0])
                    cylinder(r = safe_r, h = d, $fn = fn_val);
    }
}

// Creates the internal well with a sphere-based scoop at the bottom
module scooped_well(w, l, h, r, fn_val) {
    sr = min(r, w/2 - 0.1, l/2 - 0.1);
    hull() {
        translate([0, 0, sr]) cube([w, l, h - sr]);
        for(x = [sr, w - sr], y = [sr, l - sr])
            translate([x, y, sr]) sphere(sr, $fn = fn_val);
    }
}