Another useful Shoes widget is the *tooltip*. 

* If you already know Shoes, tooltip is meant to be a hidden slot that dynamically moves and presents information about Canvas elements chosen by the developer.
* If you dont know shoes, imagine that you are in a mute Charlie Chaplin movie and the tooltip is that guy holding a sign with what happens in the situation. Basically a situation is the object and the sign is the message presented.

Enough with the talk lets start with the real stuff. 

**1 Create the tooltip window.** 

Once created it is always present but hidden under the Canvas. It only appears when requested to do so. tooltip block is called by the **tooltip()** function.
```Ruby
Shoes.app width: 500, height: 500 do
     @the_sign_guy = tooltip()
end
```
Now you have nothing but an empty canvas and a hidden block sitting patiently.

**2 Create an object or situation and make it use the sign.**
 
Lets put an image on our canvas.
```Ruby
Shoes.app width: 500, height: 500 do
     @the_sign_guy = tooltip()
     @object_to_describe = image "#{DIR}/static/app-icon.png", :top => 40, :left => 60
end
```
Now you have the hidden sign and an image which can be seen on the canvas.
Make the image interact with the sign when hovered using the *show* method. It requires the following variables that relate to how and what it is presented.
* text: "my text" - this is the message shown on the sign. It is defined as a string.
* width: 300 - the width of the sign.
* height: 50 - the height of the sign.

Right now I want a sign to appear when your mouse cursor is on top of the picture.
Launch the code below and check try it out.

```Ruby
Shoes.app width: 500, height: 500 do
     @the_sign_guy = tooltip()
     @object_to_describe = image "#{DIR}/static/app-icon.png", :top => 40, :left => 60
     @object_to_describe.hover do
        @the_sign_guy.show text: "Got your shoes on?", width: 300, height: 50
     end
end 
```
**3 Keep the sign guy away.**

If you tested the code above you may have noticed that when the sign appeared it stayed there forever. Tell him to go away. You can do this by using the *hide* method. Lets say I want the sign to go away when mouse cursor leaves the object.

```Ruby
Shoes.app width: 500, height: 500 do
     @the_sign_guy = tooltip()
     @object_to_describe = image "#{DIR}/static/app-icon.png", :top => 40, :left => 60
     @object_to_describe.hover do
        @the_sign_guy.show text: "Got your shoes on?", width: 300, height: 50
     end
     @object_to_describe.leave do
        @the_sign_guy.hide
     end
end 
```

**4 You want to get freaky?**

You like the idea but default design sucks? We got you covered. There are a handful of optional settings the user can adjust. Here is the full list:
*stroke: "green" - Changes message text colour
*size: 15 - Changes message text size
*font: "Vivaldi" - Changes message font
*border: rgb(80,122,25,0.5) - Changes sign border colour 
*background: rgb(30,30,30,0.5) - Changes sign background colour

**5 Transparent sign**

Having a transparency is done by making the border and background colour semi transparent. 
You do this by editing the transparency variable when setting the RGB colour scheme (red,green,blue,**transparency** of the alpha channel). Once both are transparent have in mind that the background colour of the sign will be a mix between the Border and the Background colour. Most useful range for transparency are numbers between 0.4 and 0.6.