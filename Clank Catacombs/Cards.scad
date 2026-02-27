// Width of a single card
CardWidth = 92;    

// Height of a single card
CardHeight = 68;  

// Box Height
BoxHeight = 69; 

// Size of each Card slot
Slots = [30, 30, 95];

// Number of rows of cards
Rows = 1;

// Slant the front of the box 
SlantFront = true;

// Labels for each card slot  (only recommended when Rows=1)
Labels = [];

// Size of botton cutout, % of width
Removal = 0.4;
AccessDepth = 0.4;

// Wall Thickness
gWT = 0.75;

// Roundness
$fn = 20;

function SumList(list, start, end) = (start == end) ? list[start] : list[start] + SumList(list, start+1, end);

module RCube(x,y,z,ipR=4) {
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



Angle = (((BoxHeight-gWT)/CardHeight) < 1) ? acos((BoxHeight-gWT)/CardHeight) : 0;
  
//Wall space for tilted wall
gWS =  gWT / cos(Angle);
BoxWidth = CardWidth + 2*gWT;

SlotsAdj = [for (i = [0:len(Slots)-1]) Slots[i]/cos(Angle)];
ExtraLength = CardHeight * sin(Angle);
BoxLength = SumList(SlotsAdj,0,len(SlotsAdj)-1) + ExtraLength + (len(Slots)-1) * gWS+ 2*gWT;
RailPlace = [for (i = [0:len(Slots)-1]) gWT-BoxLength/2+SumList(SlotsAdj,0,i)+gWS*i ];
LabelPlace = [for (i = [0:len(Slots)-1])  (i == 0) ? ((-BoxLength/2)+RailPlace[0])/2 + ExtraLength : (RailPlace[i-1] + RailPlace[i])/2 + ExtraLength];
    


// final dimensions 
echo(BoxLength,BoxWidth, Angle);

//  Main Box
module Box() {
   intersection() 
   {
     RCube(BoxLength,BoxWidth,BoxHeight, 1);  
     difference() 
     {  
        union() 
        { 
           difference() 
           {    
              RCube(BoxLength,BoxWidth,BoxHeight, 1);
                   
              // Hallow out the box  
              translate([gWT/2,0,BoxHeight/2+gWT]) cube([BoxLength-gWT,BoxWidth-2*gWT,BoxHeight], center=true);
                   
              // Add the names to both sides
              for(x=[0:len(Slots)-1]) {      
                    translate ([LabelPlace[x],-BoxWidth/2+0.4,BoxHeight-gWT])rotate([90,0,0]) linear_extrude(0.4) text(Labels[x], size = 4, spacing = 0.9, direction = "ttb",  font="Helvetica:style=Bold");
                    translate ([LabelPlace[x],BoxWidth/2-0.4,BoxHeight-gWT])rotate([90,0,180]) linear_extrude(5) text(Labels[x], size = 4, spacing = 0.9, direction = "ttb",  font="Helvetica:style=Bold");
                 }  // end For
           }  // shell of box
              
           // add the dividers  
           for(x=[0:len(Slots)-1]) {  
              translate([RailPlace[x]-0.2,0,gWT-CardHeight/2])  translate([1,0,CardHeight/2]) rotate([0,Angle,0]) translate([0,0,CardHeight/2]) cube([2, CardWidth, CardHeight],center=true);
           }
               
           // Add new front if configured
           if (SlantFront)
           {
               translate([-BoxLength/2,0,gWT]) rotate([0,Angle,0]) translate([0,0,CardHeight/2]) cube([2, CardWidth, CardHeight],center=true);        
           } 
        } // End the union after here is substraction
              
        // create gap at top to access the cards
        AccessWidth = CardWidth * 0.4;
        hull(){
            translate([0,-AccessWidth/2+6,BoxHeight+10]) rotate([0,90,0])cylinder(r=6,h=BoxLength,center=true);;
            translate([0,AccessWidth/2-6,BoxHeight+10]) rotate([0,90,0])cylinder(r=6,h=BoxLength,center=true);;
            translate([0,-AccessWidth/2+6,BoxHeight*(1-AccessDepth)])rotate([0,90,0])cylinder(r=6,h=BoxLength,center=true);;
            translate([0,AccessWidth/2-6,BoxHeight*(1-AccessDepth)])rotate([0,90,0])cylinder(r=6,h=BoxLength,center=true);;
        } // hull
         
            translate([0,-AccessWidth/2-6,BoxHeight-6])difference(){
               cube([BoxLength,12.1,12.1], center = true);
               rotate([0,90,0])cylinder(r=6,h=BoxLength,center=true);
                translate([0,-6,0])cube([BoxLength,12,12], center = true);
                translate([0,0,-6])cube([BoxLength,12,12], center = true);
            }
           translate([0,+AccessWidth/2+6,BoxHeight-6]) difference(){
               cube([BoxLength,12.1,12.1], center = true);
               rotate([0,90,0])cylinder(r=6,h=BoxLength,center=true);
                translate([0,6,0])cube([BoxLength,12,12], center = true);
                translate([0,0,-6])cube([BoxLength,12,12], center = true);
            }
//           rotate([0,90,0]) triangle(6, 6, BoxLength+10, center = true);
            
        
        

        // Remove some from the bottem to reduce plastic
        hull() {
            translate([BoxLength/2-(BoxWidth*Removal/2)-15,0,0]) sphere(r=(BoxWidth*Removal)/2);
            translate([-BoxLength/2+(BoxWidth*Removal/2)+15,0,0]) sphere (r=(BoxWidth*Removal)/2);
        }
           
        // If we have the slanted front remove part of the box
        if (SlantFront)
        {
           hull() { 
             translate([-BoxLength/2-200,0,gWT]) rotate([0,Angle,0]) translate([0,0,CardHeight/2]) cube([2, CardWidth+10, CardHeight+2*gWT],center=true);
             translate([-BoxLength/2-2,0,gWT]) rotate([0,Angle,0]) translate([0,0,CardHeight/2]) cube([2, CardWidth+10, CardHeight+2*gWT],center=true);
              }
        } // end slant
      } // end diff
   }  // Instersection
}

for(i=[0:Rows-1]) { translate([0,i * (BoxWidth-gWT),0]) Box(); }


