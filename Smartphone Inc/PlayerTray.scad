$fn=60; 

/* [Global] */
x_sizes = [61, 61];
y_sizes = [40.5, 40.5];
z_size = 22;
RailHeight = 4.0; 

/* [Design Tweaks] */
OpeningRatio = 0.9; 
gWT = 1.2;
ipR = 8;
// The radius for the bottom corners of the cutout
BottomCornerRadius = 2.0;

/* [Hidden] */
TotalZ = z_size;
AdjBoxHeight = TotalZ - RailHeight;

function SumList(list, start, end) = (start == end) ? 0 : list[start] + SumList(list, start+1, end);
TotalX = SumList(x_sizes,0,len(x_sizes)) + gWT*(len(x_sizes)+1);
TotalY = SumList(y_sizes,0,len(y_sizes)) + gWT*2 + gWT*(len(y_sizes)-1);

module RCube(x,y,z,ipR=ipR) {
    translate([-x/2,-y/2,0]) hull(){
      translate([ipR,ipR,ipR]) sphere(ipR);
      translate([x-ipR,ipR,ipR]) sphere(ipR);
      translate([ipR,y-ipR,ipR]) sphere(ipR);
      translate([x-ipR,y-ipR,ipR]) sphere(ipR);
      translate([ipR,ipR,z-ipR]) sphere(ipR);
      translate([x-ipR,ipR,z-ipR]) sphere(ipR);
      translate([ipR,y-ipR,z-ipR]) sphere(ipR);
      translate([x-ipR,y-ipR,z-ipR]) sphere(ipR);
    }  
} 

module box () {
  // 1. MAIN CONTAINER BODY
  difference() {    
    translate ([0,0,AdjBoxHeight/2]) cube([TotalX,TotalY,AdjBoxHeight], center = true);

    for(nX=[0:len(x_sizes)-1]) {
      for(nY=[0:len(y_sizes)-1]) {
          xOffset = SumList(x_sizes,0,nX) + gWT*(nX+1) + x_sizes[nX]/2 - TotalX/2;
          yOffset = SumList(y_sizes,0,nY) + gWT*(nY+1) + y_sizes[nY]/2 - TotalY/2;
          translate([xOffset,yOffset,gWT]) RCube(x_sizes[nX], y_sizes[nY] ,AdjBoxHeight+20);
      }
    }
  }

  // 2. TOP RAIL SECTION
  translate([0, 0, AdjBoxHeight]) {
    difference() {
        // The solid ring
        translate([0,0,RailHeight/2]) 
            difference() {
                cube([TotalX, TotalY, RailHeight], center = true);
                cube([TotalX - (gWT*2), TotalY - (gWT*2), RailHeight + 0.1], center = true);
            }
        
        // 3. RECTANGULAR CUTOUT WITH ROUNDED BOTTOM CORNERS
        opening_width = TotalY * OpeningRatio;
        r = BottomCornerRadius;

        translate([-TotalX/2, 0, 0])
        hull() {
            // Bottom rounded corners (Spheres)
            // These create the curve at the base of the notch
            translate([-gWT, -(opening_width/2 - r), r]) rotate([0,90,0]) cylinder(h=gWT*4, r=r, center=true);
            translate([-gWT,  (opening_width/2 - r), r]) rotate([0,90,0]) cylinder(h=gWT*4, r=r, center=true);
            
            // Top sharp corners (Cubes/Blocks)
            // By using cubes at the top of the hull, the vertical edges stay straight/sharp
            translate([-gWT*2, -opening_width/2, RailHeight - 0.1]) cube([gWT*4, 0.1, 0.1]);
            translate([-gWT*2,  opening_width/2 - 0.1, RailHeight - 0.1]) cube([gWT*4, 0.1, 0.1]);
        }
    }
  }
} 

// Final Render
intersection() {
    box();
    RCube(TotalX,TotalY,TotalZ,1);
}