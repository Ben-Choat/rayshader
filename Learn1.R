# BChoat 2024/08/25

# first approach to learning rayshader in R.
# starting with very basic toy examples

# all of these examples came from: 
# https://github.com/tylermorganwall/rayshader?tab=readme-ov-file

# install.packages('devtools')
load_install <- function(package) {
    if (!require(package)) {
    install.packages(package)
    }
}
packages <- c('rayshader', 'ambient', 'magick', 'ggplot2')

for (package in packages) {print(package[1]); load_install(package[1])}

library(rayshader)
library(ggplot2)



# ex 1
#Here, I load a map with the raster package.
loadzip <- tempfile() 
download.file("https://tylermw.com/data/dem_01.tif.zip", loadzip)
localtif <- raster::raster(unzip(loadzip, "dem_01.tif"))
unlink(loadzip)

#And convert it to a matrix:
elmat <- raster_to_matrix(localtif)

#We use another one of rayshader's built-in textures:
elmat %>%
  sphere_shade(texture = "desert") %>%
  plot_map()



#sphere_shade can shift the sun direction:
elmat %>%
  sphere_shade(sunangle = 45, texture = "desert") %>%
  plot_map()


# elmat <- raster_to_matrix(localtif)

elmat %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(elmat), color = "desert") %>%
  plot_map()


  #And we can add a raytraced layer from that sun direction as well:
elmat %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(elmat), color = "desert") %>%
  add_shadow(ray_shade(elmat), 0.5) %>%
  plot_map()


#And here we add an ambient occlusion shadow layer, which models 
#lighting from atmospheric scattering:

elmat %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(elmat), color = "desert") %>%
  add_shadow(ray_shade(elmat), 0.5) %>%
  add_shadow(ambient_shade(elmat), 0) %>%
  plot_map()



# Rayshader also supports 3D mapping by passing a texture map (either external
#  or one produced by rayshader) into the plot_3d function.
elmat %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(elmat), color = "desert") %>%
  add_shadow(ray_shade(elmat, zscale = 3), 0.5) %>%
  add_shadow(ambient_shade(elmat), 0) %>%
  plot_3d(elmat,
          zscale = 10,
          fov = 0, theta = 135,
          zoom = 0.75,
          phi = 45,
          windowsize = c(1000, 800))
Sys.sleep(0.2)
render_snapshot()

# You can add a scale bar, as well as a compass using 
# render_scalebar() and render_compass()

render_camera(fov = 0, theta = 60, zoom = 0.75, phi = 45)
render_scalebar(limits=c(0, 5, 10),label_unit = "km",position = "W", y=50,
                scale_length = c(0.33,1))
render_compass(position = "E")
render_snapshot(clear = TRUE)





# Rayshader also includes the option to add a procedurally-generated cloud layer (and optionally, shadows):

elmat %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(elmat), color = "lightblue") %>%
  add_shadow(cloud_shade(
    elmat, zscale = 10, start_altitude = 500, end_altitude = 1000,
    ), 0) %>%
  plot_3d(elmat, zscale = 10, fov = 0, 
            theta = 135, zoom = 0.75, phi = 45, windowsize = c(1000, 800),
          background = "darkred")
render_camera(theta = 20, phi = 40,zoom = 0.64, fov = 56)

render_clouds(elmat, zscale = 10, start_altitude = 800,
                end_altitude = 1000, attenuation_coef = 2, clear_clouds = T)
render_snapshot(clear = TRUE)


# These clouds can be customized:

elmat %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(elmat), color = "lightblue") %>%
  add_shadow(cloud_shade(elmat,zscale = 10, start_altitude = 500, end_altitude = 700, 
                         sun_altitude = 45, attenuation_coef = 2, offset_y = 300,
              cloud_cover = 0.55, frequency = 0.01, scale_y=3, fractal_levels = 32), 0) %>%
  plot_3d(elmat, zscale = 10, fov = 0, theta = 135, zoom = 0.75, phi = 45, windowsize = c(1000, 800),
          background="darkred")
render_camera(theta = 125, phi=22,zoom= 0.47, fov= 60 )

render_clouds(elmat, zscale = 10, start_altitude = 500, end_altitude = 700, 
              sun_altitude = 45, attenuation_coef = 2, offset_y = 300,
              cloud_cover = 0.55, frequency = 0.01, scale_y=3, fractal_levels = 32, clear_clouds = T)
render_snapshot(clear=TRUE)




# You can also render using the built-in pathtracer, powered by rayrender.
# Simply replace render_snapshot() with render_highquality(). When
# render_highquality() is called, there’s no need to pre-compute the shadows
#  with any of the _shade() functions, so we remove those:
elmat %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(elmat), color = "desert") %>%
  plot_3d(elmat, zscale = 10, fov = 0, theta = 60, zoom = 0.75, phi = 45, windowsize = c(1000, 800))

render_scalebar(limits=c(0, 5, 10),label_unit = "km",position = "W", y=50,
                scale_length = c(0.33,1))

render_compass(position = "E")
Sys.sleep(0.2)
render_highquality(samples=200, scale_text_size = 24,clear=TRUE)



# You can also easily add a water layer by setting water = TRUE
# in plot_3d() (and setting waterdepth if the water level is
# not 0), or by using the function render_water() after the
# 3D map has been rendered. You can customize the appearance
# and transparancy of the water layer via function arguments.
# Here’s an example using bathymetric/topographic data of Monterey
# Bay, CA (included with rayshader):

montshadow <- ray_shade(montereybay, zscale = 50, lambert = FALSE)
montamb <- ambient_shade(montereybay, zscale = 50)
montereybay %>%
    sphere_shade(zscale = 10, texture = "imhof1") %>%
    add_shadow(montshadow, 0.5) %>%
    add_shadow(montamb, 0) %>%
    plot_3d(montereybay, zscale = 50, fov = 0, theta = -45, phi = 45,
            windowsize = c(1000, 800), zoom = 0.75,
            water = TRUE, waterdepth = 10, wateralpha = 0.5, 
            watercolor = "lightblue",
            waterlinecolor = "white", waterlinealpha = 0.5)
Sys.sleep(0.2)
render_snapshot(clear = TRUE)



# Water is also supported in render_highquality().
# We load the rayrender package to change the ground
# material to include a checker pattern. By default, 
# the camera looks at the origin, but we shift it down
# slightly to center the map.

library(rayrender)
## 
## Attaching package: 'rayrender'

## The following object is masked from 'package:rgl':
## 
##     text3d
montereybay %>%
    sphere_shade(zscale = 10, texture = "imhof1") %>%
    plot_3d(montereybay, zscale = 50, fov = 70, theta = 270, phi = 30, 
            windowsize = c(1000, 800), zoom = 0.6,  
            water = TRUE, waterdepth = 0, wateralpha = 0.5, watercolor = "#233aa1",
            waterlinecolor = "white", waterlinealpha = 0.5)
Sys.sleep(0.2)
render_highquality(lightdirection = c(-45,45), lightaltitude  = 30, clamp_value = 10, 
                   samples = 256, camera_lookat= c(0,-50,0),
                   ground_material = diffuse(color="grey50",checkercolor = "grey20", checkerperiod = 100),
                   clear = TRUE)






# Adding text labels is done with the render_label() function,
# which also allows you to customize the line type, color,
# and size along with the font:

montereybay %>%
  sphere_shade(texture = "desert") %>%
  add_shadow(ray_shade(montereybay,zscale=50)) %>%
  plot_3d(montereybay,water=TRUE, windowsize=c(1000,800), watercolor="dodgerblue")
render_camera(theta=-60,  phi=60, zoom = 0.85, fov=30)

#We will apply a negative buffer to create space between adjacent polygons:
sf::sf_use_s2(FALSE) 
mont_county_buff = sf::st_simplify(sf::st_buffer(monterey_counties_sf,-0.003), dTolerance=0.004)




montereybay %>% 
    sphere_shade(zscale = 10, texture = "imhof1") %>% 
    add_shadow(montshadow, 0.5) %>%
    add_shadow(montamb,0) %>%
    plot_3d(montereybay, zscale = 50, fov = 0, theta = -100, phi = 30, windowsize = c(1000, 800), zoom = 0.6,
            water = TRUE, waterdepth = 0, waterlinecolor = "white", waterlinealpha = 0.5,
            wateralpha = 0.5, watercolor = "lightblue")
render_label(montereybay, x = 350, y = 160, z = 1000, zscale = 50,
             text = "Moss Landing", textsize = 2, linewidth = 5)
render_label(montereybay, x = 220, y = 70, z = 7000, zscale = 50,
             text = "Santa Cruz", textcolor = "darkred", linecolor = "darkred",
             textsize = 2, linewidth = 5)
render_label(montereybay, x = 300, y = 270, z = 4000, zscale = 50,
             text = "Monterey", dashed = TRUE, textsize = 2, linewidth = 5)
render_label(montereybay, x = 50, y = 270, z = 1000, zscale = 50,  textcolor = "white", linecolor = "white",
             text = "Monterey Canyon", relativez = FALSE, textsize = 2, linewidth = 5) 
Sys.sleep(0.2)
render_snapshot(clear=TRUE)






# 3D paths, points, and polygons can be added directly
# from spatial objects from the sf library:
moss_landing_coord = c(36.806807, -121.793332)
x_vel_out = -0.001 + rnorm(1000)[1:500]/1000
y_vel_out = rnorm(1000)[1:500]/200
z_out = c(seq(0,2000,length.out = 180), seq(2000,0,length.out=10), 
          seq(0,2000,length.out = 100), seq(2000,0,length.out=10))

bird_track_lat = list()
bird_track_long = list()
bird_track_lat[[1]] = moss_landing_coord[1]
bird_track_long[[1]] = moss_landing_coord[2]

for(i in 2:500) {
  bird_track_lat[[i]] = bird_track_lat[[i-1]] + y_vel_out[i]
  bird_track_long[[i]] = bird_track_long[[i-1]] + x_vel_out[i]
}


montereybay %>% 
    sphere_shade(zscale = 10, texture = "imhof1") %>% 
    add_shadow(montshadow, 0.5) %>%
    add_shadow(montamb,0) %>%
    plot_3d(montereybay, zscale = 50, fov = 0, theta = -100, phi = 30, windowsize = c(1000, 800), zoom = 0.6,
            water = TRUE, waterdepth = 0, waterlinecolor = "white", waterlinealpha = 0.5,
            wateralpha = 0.5, watercolor = "lightblue")
render_label(montereybay, x = 350, y = 160, z = 1000, zscale = 50,
             text = "Moss Landing", textsize = 2, linewidth = 5)
render_label(montereybay, x = 220, y = 70, z = 7000, zscale = 50,
             text = "Santa Cruz", textcolor = "darkred", linecolor = "darkred",
             textsize = 2, linewidth = 5)
render_label(montereybay, x = 300, y = 270, z = 4000, zscale = 50,
             text = "Monterey", dashed = TRUE, textsize = 2, linewidth = 5)
render_label(montereybay, x = 50, y = 270, z = 1000, zscale = 50,  textcolor = "white", linecolor = "white",
             text = "Monterey Canyon", relativez = FALSE, textsize = 2, linewidth = 5) 
render_points(extent = attr(montereybay,"extent"), 
              lat = unlist(bird_track_lat), long = unlist(bird_track_long),
              altitude = z_out, zscale=50, color = "red")
render_highquality(point_radius = 1, samples = 256)
Sys.sleep(0.2)
render_snapshot(clear=TRUE)



##
montereybay %>% 
    sphere_shade(zscale = 10, texture = "imhof1") %>% 
    add_shadow(montshadow, 0.5) %>%
    add_shadow(montamb,0) %>%
    plot_3d(montereybay, zscale = 50, fov = 0, theta = -100, phi = 30, windowsize = c(1000, 800), zoom = 0.6,
            water = TRUE, waterdepth = 0, waterlinecolor = "white", waterlinealpha = 0.5,
            wateralpha = 0.5, watercolor = "lightblue")
render_label(montereybay, x = 350, y = 160, z = 1000, zscale = 50,
             text = "Moss Landing", textsize = 2, linewidth = 5)
render_label(montereybay, x = 220, y = 70, z = 7000, zscale = 50,
             text = "Santa Cruz", textcolor = "darkred", linecolor = "darkred",
             textsize = 2, linewidth = 5)
render_label(montereybay, x = 300, y = 270, z = 4000, zscale = 50,
             text = "Monterey", dashed = TRUE, textsize = 2, linewidth = 5)
render_label(montereybay, x = 50, y = 270, z = 1000, zscale = 50,  textcolor = "white", linecolor = "white",
             text = "Monterey Canyon", relativez = FALSE, textsize = 2, linewidth = 5) 
render_path(extent = attr(montereybay,"extent"),  
            lat = unlist(bird_track_lat), long = unlist(bird_track_long), 
            altitude = z_out, zscale=50,color="white", antialias=TRUE)
render_highquality(line_radius = 1,samples=256, clear=TRUE)
Sys.sleep(0.2)
render_snapshot(clear=TRUE)












# You can also apply a post-processing effect to the 
# 3D maps to render maps with depth of field with the
# render_depth() function:

elmat %>%
  sphere_shade(texture = "desert") %>%
  add_water(detect_water(elmat), color = "desert") %>%
  add_shadow(ray_shade(elmat, zscale = 3), 0.5) %>%
  add_shadow(ambient_shade(elmat), 0) %>%
  plot_3d(elmat, zscale = 10, fov = 30, theta = -225, phi = 25, windowsize = c(1000, 800), zoom = 0.3)
Sys.sleep(0.2)
render_depth(focallength = 800, clear = TRUE)













# 3D plotting with rayshader and ggplot2
# Rayshader can also be used to make 3D plots out of
# ggplot2 objects using the plot_gg() function. Here, I
# turn a color density plot into a 3D density plot.
# plot_gg() detects that the user mapped the fill aesthetic to
# color and uses that information to project the figure into 3D.

library(ggplot2)

ggdiamonds = ggplot(diamonds) +
  stat_density_2d(aes(x = x, y = depth, fill = stat(nlevel)), 
                  geom = "polygon", n = 200, bins = 50, contour = TRUE) +
  facet_wrap(clarity~.) +
  scale_fill_viridis_c(option = "A")

par(mfrow = c(1, 2))

plot_gg(ggdiamonds, width = 5, height = 5, raytrace = FALSE, preview = TRUE)
plot_gg(ggdiamonds, width = 5, height = 5, multicore = TRUE, scale = 250, 
        zoom = 0.7, theta = 10, phi = 30, windowsize = c(800, 800))
Sys.sleep(0.2)
render_snapshot(clear = TRUE)