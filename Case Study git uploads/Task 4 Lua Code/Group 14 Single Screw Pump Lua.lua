---------------------------------Case Study Cyper Physical Production Systems using AM (SS2023)------------------------------------------

---------------------------------------Guided by: Prof. Dr. Ing. Stefan Scherbarth-------------------------------------------------------

--Group : 14, Topic : Single Screw Pump
--Group Members : Gokul Kallingapuram Manoharan      - 22210892
--                Athul Dev Nedumparambil Prasenan   - 22212087
--                Jerry Jacob                        - 22211985 


--enable_variable_cache = true

----------------------------------------------------User Interface-----------------------------------------------------------------------

View_list = {
    {0, "Presentation view"},
    {1, "Cross Section"},
    {2, "Print View"}
}

      --Creates a button to select an existing file. The return value is the file path

view = ui_radio("View:", View_list)

      --Creates a combo box to interactively choose a string value from a list.

len = ui_number("Length", 50, 30, 200)  --Length of the pump with default value of 100, upper limit of 200 and lower limit of 30
pit = ui_number("pitch", 6, 3, 20)       --Pitch of the pump with default value of 6, upper value of 10 and lower value of 3
diameter = ui_number("Diameter", 6, 4, 10) -- Diameter of the Rotor with default value of 6, upper limit of 10 and lower limit of 3
sc = ui_scalar("Scale", 1.5, 0.1, 3)          --Global scaling of the pump
ra = ui_scalarBox("movement",0,10)
      --Creates a sliding bar to interactively set an integer value between min and max.


stator_offset = diameter/2  --The offset between two circles in the stator cut is the radius of the circle

len2 = -stator_offset --len2 is defined as the negative length of stator offset which will be used later in function stator shape

------------------------------------------------Stator shape function--------------------------------------------------------------------
function stator_shape(offset_length, d, n_points)


    --A function is defined which takes 3 arguments, diameter of semi circle and number of points by which the semi circle is plotted     
    --The function creates two semicircles which are opposite to eachother and their end points are joined together

    local p1_XY = {}
    local p2_XY = {}

    --Two open arrays are declared to hold values  
    local cos_phi, sin_phi
    for n = 1, n_points do
        local phi = math.pi * (n - 1) / n_points
        cos_phi = math.cos(phi)
        sin_phi = math.sin(phi)
        p1_XY[n] = translate(0, -len2, 0) * v(cos_phi * d, sin_phi * d, 5)
        p2_XY[n] = rotate(0, 0, 180) * translate(0, stator_offset, 0) * v(cos_phi * d, sin_phi * d)


      --A for loop is initialised in which n is iterated from 1 to n_points 
    --phi is an angle that varies in the loop 
    --p1_XY generates a semicircle 
    --p2_XY generates another semicircle which is opposite to p1_XY 
    end

    p1_XY[1] = p2_XY[#p2_XY]
    p1_XY[#p1_XY] = p2_XY[1]
    for n = 1, #p2_XY - 1 do
        table.insert(p1_XY, p2_XY[n])
    end

      --Two end points of the semicircles are joined to create a closed contour
   
    return p1_XY
      --The values are returned to p1_XY
end

-------------------------------------------------Rotor Function----------------------------------------------------------------------------
function rotor_shape(length, d, n_points)

      --The function rotor_shape creates circle which will be used to create the rotor
    local p1_XY = {}


    local cos_phi, sin_phi
    for n = 1, n_points do
        local phi = 2*math.pi * (n - 1) / n_points
        cos_phi = math.cos(phi)
        sin_phi = math.sin(phi)
        p1_XY[n] = translate(0, len2, 0) * v(cos_phi * d, sin_phi * d, 5)

    end
    -- Circle is plotted an the values are stored in p1_XY
    return p1_XY

    --The values are returned to p1_XY
end

----------------------------------------------------Extrude Function--------------------------------------------------------------------------
function extrude(Contour, angle, dir_v, z_steps)

     --The function extrudes takes four arguments
   -- Contour, to extrude a Contour to a shape by turning the contour to angle in z_steps
   -- extrude a Contour in a dircetion given by the vector dir_v
   -- extrude a Contour with a scaling factor given by vector scale_v 
   -- Contour: a table of vectors as a closed contour (start point and end point is the same)
   -- angle: roation angle of contour along z_steps in deg
   -- dir_v: vector(x,y,z) direction of extrusion
   -- z_steps: number of steps for the shape, mostly z_steps=2 if angle is equal zero
    local angle_rad = math.rad(angle)
    local Contours = {}

    -- n counter over contour points
    for n = 1, z_steps do
        local phi = angle_rad * (n - 1) / (z_steps - 1)
        local dir_vh = dir_v * (n - 1) / (z_steps - 1)
        local mod_contour = {}
        -- loop over contour points without end point because start is end point
          -- Calculate contur of vertex points by roating and scaling
        for i = 1, #Contour - 1 do
            local x = Contour[i].x
            local y = Contour[i].y
            local modified_vertex = v(
                dir_vh.x + (x * math.cos(phi) - y * math.sin(phi)),
                dir_vh.y + (x * math.sin(phi) + y * math.cos(phi)),
                dir_vh.z
            )
            mod_contour[i] = modified_vertex
        end
 -- end loop over points of contour
        mod_contour[#mod_contour + 1] = mod_contour[1]
        Contours[n] = mod_contour

-- Calc. the modified contour for a z_level
    end

    return sections_extrude(Contours)
-- return shape
end

----------------------------------------------------Flange Function--------------------------------------------------------------------------
function flange(dia_hole,dia_big,hole_num,hole_circle)
    --This function creates the tube flange which is used at the inlet and outlet
  local base = translate(0,0,0)*cylinder (dia_hole*2,8)
    -- The base of the flange used is a cylinder
  local plate = translate(0,0,8)*difference(cylinder(dia_big,3), cone (dia_hole*1.2,dia_hole/1.5,5))

    --The plate that will be used to mount the screws  
  local cut = cone (dia_hole*1.5,dia_hole*1.2,8)


  local flange_full= union(base, plate)
  local flange_full = difference(flange_full, cut)


  local circle_radius = hole_circle -- Radius of the screw circle
  local num_holes = hole_num -- Number of screw holes to emit

  local angleStep = (2 * math.pi) / num_holes

  local cylinders = {} -- Table to store the smaller cylinders

  for i = 1, num_holes do
    local angle = (i - 1) * angleStep
    local x = circle_radius * math.cos(angle)
    local y = circle_radius * math.sin(angle)
    local z = 0
    local cylinder1 = translate(x, y, 8) * cylinder(1, 5)
  table.insert(cylinders, cylinder1)
  end

  --A loop iterates points of a circle in which the holes will be placed

  for i, cylinder1 in ipairs(cylinders) do
    flange_full = difference(flange_full, cylinder1) -- Subtract each smaller cylinder from the result
  end
  return flange_full
end



------- Bearing to hold the connecting shaft------
b1=translate(0,0,0)*rotate(0,0,0)*cylinder(diameter*1.45,5)

b2=translate(0,0,0)*rotate(0,0,0)*cylinder(1.8,5)

bearing2 = rotate(90,0,0)*difference(b1,b2)


  cy1=difference(cylinder(4,15),cube(2.2,2.2,4))
  cy2= translate(0,0,12)*rotate(90,0,0)*cylinder(3,25)

  cy3 = translate(0,-22,12)*rotate(0,0,0)*cylinder(3,15)

  handle = union{cy1,cy2,cy3}
  handle =rotate(0,90,90)*handle
--------------------------------------------------

--------------------stand-------------------------
function stand(width,height)
  local mid= cube(width+5,width+5,height)
  local low1 = translate(-20,0,0)*rotate(0,90,0)*cube(width,width+5,40)
  local low2 = translate(0,20,0)*rotate(90,0,0)*cube(width+5,width,40)
  local hig2 = translate(0,20,height)*rotate(90,0,0)*cube(width+30,width,40)
  local stand = union{mid,low1,low2,hig2}
return stand
end
-------------------------------------------------

--------------universal joint--------------------
  cut = translate (0,2,0)*cube(6,6,4)
  yolk_base =difference(cube(10,8,4),cut)
  yolk_base = translate(0,0,1)*yolk_base
  c_hole1=(translate(3,4,3)*rotate(0,90,0)*cylinder(2,2))
  c_hole2=(translate(-5,4,3)*rotate(0,90,0)*cylinder(2,2))
  stopper1= translate(5,4,3)*rotate(0,-90,0)*difference(cylinder(1.4,2),translate(0,0,1)*cylinder(1,4))

  stopper2 = translate(-5,4,3)*rotate(0,90,0)*difference(cylinder(1.4,2),translate(0,0,.4)*cylinder(1,4))

  stopper = union(stopper1,stopper2)
  stopper = stopper
  yoke = union{yolk_base,c_hole1,c_hole2}

  yoke_hole = translate(-10,4,3)*rotate(0,90,0)*cylinder(1.5,22)
  yoke1= difference(yoke,yoke_hole)
  yoke2  = union(yoke1,stopper)
  yoke2 =rotate(3,0,0)*yoke2

  yoke_final = union{yoke2,translate(3,8,3)*rotate(177,90,0)*yoke2}

  crosss = union{translate(0,0,-1)*rotate(0,0,0)*cylinder(0.8,8),translate(-4,0,3)*rotate(0,90,0)*cylinder(0.8,8),translate(0,1,3)*rotate(90,0,0)*cylinder(2.5,1.8)}
  crosss =translate(0,4,0)*crosss
  universal_joint = union(yoke_final,crosss)
  shaft_driving = union((translate(0,-4,2.7)*rotate(93,0,0)*cylinder(1.6,16)),translate(0,-20,0.8)*rotate(3,0,0)*cube(2,4,2))
  shaft_driven = union((translate(0,22,3.2)*rotate(90,0,0)*cylinder(1.6,12)),translate(0,22,2.2)*rotate(0,0,0)*cube(2,4,2))
  shaft = union(shaft_driving,shaft_driven)
  universal_joint= union(shaft,universal_joint)

-------------------------------------------------

------------------------------------------------------------emitting---------------------------------------------------------------------------------
Double_helix= extrude(stator_shape(stator_offset, diameter, 500), 90*pit, v(0,0,len), 500)
--emit(scale(1.5)*Double_helix)
    --The double helix shape of the stator cut is emitted using function stator offset and function extrude

rotor = translate(0,-40,-1)*rotate(90,0,0)*extrude(rotor_shape(2,diameter*0.65,90), 180*pit, v(0,0,len), 500)
--emit(rotor,8)
    --The rotor shape extruded using function rotor_shape and function extrude

stator_base= cube(diameter+30,diameter+30,len)
    --A cube is created which will be used as the stator housing, in which the side in x and y axis changes with changing the diameter of the rotor and stator. 

stator_cut= translate(17,10,0)*rotate(90,0,0)*cube(diameter+30,diameter+50,len+70)
    --Another cube is created with the same dimension of stator housing which will be used to view the cut section of stator

stator=difference(stator_base,Double_helix)
--emit(stator,7)
    --The stator is obtained by removing the double helical shape from the cube
inlet_way = translate(0,-1,24)*rotate(-90,0,0)*cone(diameter,diameter*1.8,25)

    --the inlet hole for the inlet

stator = union{stator, translate(0,0,len)*flange(diameter,diameter+10,10,diameter+7),translate(0,15,-16)*rotate(-90,0,0)*flange(diameter,diameter+10,8,diameter+6)}
stator = translate(0,0,40)*rotate(0,0,0)*stator

    --The two flanges are unioned to the stator


inlet_way = translate(0,-1,34)*rotate(-90,0,0)*cone(diameter,diameter*1.8,25)

    --the inlet hole for the inlet


inlet_base= cube(diameter+30,diameter+30,50)
inlet_cut= rotate(0,0,0)*cylinder(diameter*1.5,50)
inlet_housing = difference(inlet_base,inlet_cut)
inlet_housing = difference(inlet_housing,inlet_way)
inlet_housing = translate(0,0,-10)*inlet_housing
stator = rotate(90,0,0)*union(stator,inlet_housing)

    --The part where the inlet housing is made 

stator_cut2= translate(17,-8,0)*rotate(90,0,0)*cube(diameter+30,diameter+50,len+10) 

stator_cross_section=difference(stator, stator_cut)
--emit(stator_cross_section,7)

stator_cross_section2=difference(stator, stator_cut2)
    --The cross section is obtained by using the difference function between stator and stator cut



bearing1= difference(translate(0,-35,-1)*rotate(90,0,0)*cylinder(diameter,5),translate(0,-35,-1)*rotate(90,0,0)*cube(2.2,2.2,4))
  -- bearing to connect rotor and connecting shaft
rotor= union(rotor,bearing1)





main_rotor = union{rotor,translate(0,7,0)*handle,translate(0,5,0)*bearing2,translate(0,-15,-3)*universal_joint}

main2 =union{translate(0,7,0)*handle,translate(0,-15,-3)*universal_joint}

--emit(main_rotor)

--print view 

universal_joint_print= union{translate(0,0,-5)*yoke1,translate(0,18,1)*rotate(180,0,0)*yoke1,translate(0,0,-5)*rotate(-3,0,0)*shaft_driving,translate(0,10,-5)*shaft_driven,translate(15,0,-7)*rotate(90,0,0)*crosss,translate(15,10,-5.5)*stopper,translate(15,5,-5.5)*stopper
}

rotor_print = union{translate(40,13,-10)*rotate(0,0,0)*rotor,translate(40,0,-13)*rotate(90,0,0)*bearing2}
--emit(rotor_print,8)

print1 =union{translate(60,-30,-14)*rotate(0,0,0)*universal_joint_print,translate(70,10,-14)*rotate(0,2,0)*handle}

    --The rotor is displaced by 40 units in x axis which helps to print the stator and rotor seperately


if view == 2

 then                   -- when the view is set to print_view, The stator and rotor are shown seperately
    emit(scale(sc)*rotor_print,21)
    emit(scale(sc)*print1,5)
    emit(scale(sc)*translate(5,20,0)*rotate(0,-90,0)*stator,9)
    emit(scale(sc)*translate(-45,30,-15)*stand(3,8),6)
    emit(scale(sc)*translate(-45,-30,-15)*stand(3,10),6)

elseif view == 1 then                   -- when the view is set to cross section, The stator cross section can be viewed
    emit(scale(sc)*rotor_print,8)
    emit(scale(sc)*print1,5)
    emit(scale(sc)*stator_cross_section,7)
    emit(scale(sc)*translate(-45,30,-15)*stand(3,8),6)
    emit(scale(sc)*translate(-45,-30,-15)*stand(5,8),6)

elseif view == 0 then                   --when the view is set to combined view,the rotor sits inside the stator
    emit(scale(sc)*translate(10,60,12)*rotate(0,ra,0)*main_rotor,21)    
    emit(scale(sc)*translate(10,60,12)*rotate(0,ra,0)*main2,5)
  
  
    emit(scale(sc)*translate(10,60,12)*rotate(0,-90,0)*stator_cross_section2,9)
    emit(scale(sc)*translate(10,50,-15)*stand(3,8),6)
    emit(scale(sc)*translate(10,0,-15)*stand(3,8),6)

end

-----------------------------------------------------------------Section End---------------------------------------------------------------------------------

--emit(translate(100,100,-20)*cube(1))
--emit(translate(-100,-100,-20)*cube(1))
--emit(translate(100,-100,-20)*cube(1))
--emit(translate(-100,100,-20)*cube(1))

--emit(translate(-28,15,10)*sphere(2),89)
--screenshot()