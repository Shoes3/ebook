## Charts (aka plots)

Drawing a graph or a chart or a plot? Shoes 3.3.2 (beta r2649 or better) has a plot widget. It **is not** a replacement for programs like gnuplot, LibreOffice, OpenOffice, or other professional quality programs. Shoes has a limited set of options and they don't alway work as you might expect. You can always export your data to csv and use a better program to display the data.

Now that you know what to do when disappointed. Let's have some fun!

Assume we have an array of numbers and we want to plot them. 
```ruby
Shoes.app width: 620, height: 500 do
  @values1 = [24, 22, 10, 13, 20, 8, 22]
  @grf = plot 600, 400, title: "My Graph", caption:  "my caption could be long", 
    font: "Helvetica"
  @grf.add values: @values1,  name: "foobar", min: 6, max: 26
end
```
That is about as minimal as we can get. It looks like this:
![foo1](https://cloud.githubusercontent.com/assets/222691/18075210/fdfecada-6e2f-11e6-8d62-3177925c789a.png)

You'll notice that there are two parts. Creating the plot widget and saving it as @grf and adding the array to that @grf. You can create the widget with out adding a data series to display so in truth, you could use `@grf = plot 600, 400, {}` but that's boring and the fun is in the {options}. You can graph multiple data series (up to 6 for some chart types). The {options} for **add** are important and not so obvious.  I call them "data series" because there is more information needed than just a Ruby array of values. 

The min: and max: options could be calculated for you but aren't because it gives you some control on how the 
graph looks. So much control, that you shouldn't use defaults, so are there are none. 

What if you wanted your own x-axis labels instead of the generated 1,2,3...?
```ruby
Shoes.app width: 620, height: 500 do
  @values1 = [24, 22, 10, 13, 20, 8, 22]
  @x_axis1 = ['a','b','c','d','e','f', 'g']
  @grf = plot 600, 400, title:"My Graph", caption:  "my caption could be long", 
    font: "Helvetica"
  @grf.add values: @values1, labels: @x_axis1,
       name: "foobar", min: 6, max: 26
end
```
It's a major mistake if you don't have enough strings in the x observations (labels: array) as you do in the values: array. Since labels[] are strings they could be anything. Perhaps a Date or Time string? - up to you. You should have the same number of labels[] and values[].  Shoes will auto-size the data points (observations) to the range given. I could have used `min: @values1.min, max: @values1.max` but specifying my own range is a very useful thing if your plot has two data series attached with very different scales.

 **Note:**, don't be tempted to use Ruby's  min and max functions to compute the chart options. They don't like nil values which some chart types can handle.

Inside Shoes, each plot.add adds to an array so the first data series is 0 and the second is 1. Give the data series a name: "string". Mandatory. It displays in the legend part of the box.

The first data series **add**ed to the plot also controls what is displayed in the x-axis (there is only one of those) and will control the number of ticks marks and labels drawn on the left side and right side y-axis. Ticks? I don't see any ticks? Add `auto_grid: true` to the **plot** creation.
```ruby
  @grf = plot 600, 400, title: "My Graph", caption:  "my caption could be long", 
    font: "Helvetica", auto_grid: true
```
![foo2](https://cloud.githubusercontent.com/assets/222691/18076413/f1120bba-6e3a-11e6-9e47-dc41ac41a3c0.png)

Let's use many of the options for plot and add options with a program that creates two data series, one of which has a missing value (it's nil) and an label is nil too.
![foo-3](https://cloud.githubusercontent.com/assets/222691/18076928/0f3a718c-6e3f-11e6-8c17-5fa53c840561.png)

See [gr1.rb](https://github.com/Shoes3/shoes3/blob/master/Tests/plot/gr1.rb) and comment/uncomment the settings for which set of values an labels you'd like to see.

That example also shows some more options when creating a plot. 
```ruby
   chart: "timeseries",
   default: "skip", click: proc {|btn, l, t| puts "click on #{@grf.near_x(l)}" }
```
There are several chart types - the default is "line". "Column", Scatter" and "Pie". "timeseries"  is like "line" on steroids. Not all options apply to all chart types and in this case only line and timeseries allow for a **click:** and default: only works on some chart types. 

From the gr1.rb example you can see a new option when adding a dataseries to the plot, 
```ruby
  desc: "foobar Yy"
```
That (**desc:**) is displayed in the legend and colored to match the data series. **name:** is used if **desc:** isn't given. **name:** is mandatory, **desc:** is optional.

There are two other options for the plot widget creation. Shoes doesn't know the pixel width of the 'typical' label string. By default it's somewhere around 6 characters but you do get situations where the auto_sizing needs help (depends on your data and strings, the size of the widget....). So { **x_ticks:** 4, **y_ticks:** 20} would only draw four vertical lines on the grid and 20 horizontal lines, for example. This also introduces it's own visual artifacts so you'll need to play with what works best for you and of course it only applies to plot/chart types that
accept them.

Wait, there's more options you can use when adding a data series. If you don't like the default colors, you can specify your own using the predefined names in Shoes (Manual->Shoes->Color) when you **add** a _data series_ to the plot with the **color:** "shoes_color_string" option.

You can also set a wider line width for a _data series_ with { **strokewidth:** small-int }. Anything less that one will be set to one, otherwise it wouldn't be visible. 

![plot-nubs](https://cloud.githubusercontent.com/assets/222691/18192452/8afc0fd4-7091-11e6-8086-b4fdbe66a35a.png)

You might notice in the picture there is some sort of dot drawn at each data point in the picture above. That's option { **points**: boolean }. It only looks like a circle - it's really a wee small '+' or box. The _points_ , even if specified will only show up if Shoes thinks it has enough space for the given number of data points (not that many - if width can handle 1/10 of the data - you can get points in a line or timeseries).  A data series with lots of observations (values) will turn off the points display. It just makes it slightly easier to visually find the point and figure out the data value. In some charts (scatter) you can specify "dot", "box", "circle", "rect". Dot and box are filled in and circle and rect aren't. 

### Timeseries vs Line Charts

They aren't the same except for a small number of observations. I've got timeseries data files with 4K points which doesn't fit in a 600 pixel width widget. Yet Shoes does draw all the points, you just can't see them. That is true for all charts - they draw everything given in the space they have.

Timeseries charts have some special features. You set the display indices for the left side and right side. That allows you to scroll left and right in the display, zoom it and zoom out _if you write the code to handle that._

See [grcsv.rb](https://github.com/Shoes3/shoes3/blob/master/Tests/plot/grcsv.rb)

Methods set_first and set_last change the **display** of data points.  It does not change the size of the  values and label arrays. They change the _display_ of every data series on the plot/graph. You use them to zoom in, out and scroll left or right. It's a lot work for you but if you need it, you can do it.

**redraw_to(index)** allows you to append/change data in your values and labels, in a line chart or timeseries chart and then tell Shoes to draw everything to that **index** Perhaps you are collecting a data value in real time from a sensor or some web site. **IT IS VERY IMPORTANT** that you must append the data to the values array **and** to the labels array **BEFORE** calling redraw_to. If you're managing zooming or scrolling, you need to know that it will  reset the begin and end display indexes to the begining ([0])  and end (essentially unzoom, unscroll). Manage your scroll/zoom wisely. You have the tools.
 
### Save a plot/chart

Again see that gr1.rb test. 

You can save the plot (aka) chart as a png, pdf, ps or svg. Just make sure the filename extension is one of those four lower case, strings following the last `.` - it does parse the extension. The vector formats like .pdf are a lot of fun because you can stretch them or shrink them without pixel jaggies. It's Impressive. There might be a performance or file size issue with a 6 data series of 5000 data points each drawn on the screen. They draw just fine, but I haven't tried saving that to a vector fix because since I can't fix whatever might be wrong with the file then I haven't tried.

### Column chart

Shoes doesn't do horizontal "bar" charts or stacked columns or stacked bars -- life is short. 

You can fill the background with a Shoes color name. While the
default colors can be used, you probably want one from the Shoes pallet.

In the option hash, you can specify `chart: "column"` (default is `chart: "line"`). Here's two plot widgets
[source: gr3.rb](https://github.com/Shoes3/shoes3/blob/master/Tests/plot/gr3.rb):
![bar-graph](https://cloud.githubusercontent.com/assets/222691/18612528/827e11b0-7d19-11e6-9609-f041c99b1931.png)
Looking at the code, it draws the same data into two different plots widgets, one line chart and one column chart. 
If you're paying attention, you'll notice there is no boundary box drawn around the column chart (aka plot). It's an option `{boundary_box: boolean}`, default is `:true". 

A note or two about column graphs: It would be _your mistake_ to cram too many bars in a small space. strokewidth: is how you specify the width of column. Refer to that Shoes code link. If a column value matches the given minimum value, there is no column to draw so set your min and max by hand. Just a friendly warning if you think it's not displaying a value. Been there, done that.

[gr2.rb](https://github.com/Shoes3/shoes3/blob/master/Tests/plot/gr2.rb) shows how Shoes line chart can handle missing data points and missing observation labels. **Top Tip:** Fix your data and don't depend on Shoes drawing what you think it should do if your data is wrong.

The **points:** hash argument can now take a string argument as well as a :true, :false, or nil. The string argument is one of "dot", "circle", "box", or "rect". Dot and box are filled with series color and Circle and Box are hollow so the background shows inside. The size of of the dot/circle/box/rect is related to or controlled by the strokewidth: setting and they only become visible if Shoes thinks the chart is "not too busy" and only for line, timeseries and scatter graphs.

### Scatter charts
Scatter charts are a little cumbersome and come with some odd rules and behavior in Shoes.

![almost-good-scatter](https://cloud.githubusercontent.com/assets/222691/18806307/21df17ec-81e6-11e6-908a-16c79f199b08.png)

The first rule is that it takes two @grf.add {series} - **no more** and **no less** than two. It ignores the **labels:** of both data series. The first series added is assumed to be the x (horizontal) values and the second series added is the y (vertical) values. 

The second rule is that you really should specify the minv and maxv values for both series and set them wisely. Sadly, wisely doesn't have any rules-of-thumb because Shoes chart auto_sizing rules are a bit mysterious. 

You'll also notice that a scatter plot has a different legend - the x-axis label is drawn under the x axis and the y-axis (second series) is drawn vertically on the left. You might notice that compared to a line or bar chart there is a smaller graph area to allow that.

### Pie Charts

Pie charts also have their own rules. First rule - only one data series can be added. **Exactly one**. And the x-axis labels (strings) are used to build the legend, which is displayed near the right-top. Auto-grid :true means to draw a box around the legend (not the chart space).
![pie-finished](https://cloud.githubusercontent.com/assets/222691/19026410/d3440eea-88e2-11e6-9e5a-4d338e4b2701.png)

One other thing you can do on a pie chart is specify `**pie_percent:** true` if you want the labels to be a percentage instead of their value. 

**[Oct 19, 2016]**
**Wait**, There is more! Don't like the default colors for the pie chart?  We've got an option when you create the _plot_ widget so you can specify your own default colors:

`colors: ["yellow", "olive"]` sets the first two default colors. That replaces the default "blue" and "red" because we only have two colors, the other 12 default colors remain. Obviously, you don't want to do this without thinking about the details. Those defaults, Shoes or Yours show up when ever you don't explicitly set a color for a chart_series - in some charts like pie, its the only way to change the colors.

### Radar Charts

This may be confusing since it works differently than just adding some dataseries to the plot widget. We need to add some options to the plot creation and one of them is a Ruby array of arrays which is named `column_settings:`

```ruby
# Radar graph - 
Shoes.app width: 620, height: 480 do
  @pre_test =  [71, 35, 62, 55, 88, 76, 55] 
  @practice =  [70, 53, 83, 94, 71, 59, 82]
  @post_test = [94, 93, 96, 89, 96, 88, 93]
  @dimensions = [ ["Anger", 0, 100, "%3.0f%%"], 
               ["Contempt", 0, 100, "%3.0f%%"],
               {label: "Disgust", min: 0, max: 100, format: "%3.0f%%"},
               ["Fear", 0, 100, "%3.0f%%"],
               ["Joy", 0, 100, "%3.0f%%"],
               ["Sadness", 0, 100, "%3.0f%%"],
               ["Surprise", 0, 100, "%3.0f%%"]
             ]
  stack do
    para "Plot Radar Demo 7"
    flow do 
      button "quit" do Shoes.quit end
    end
    widget_width = 600
    widget_height = 400
    stack do
      flow do
        @grf = plot widget_width, widget_height, title: "Microexpressions Scores", 
          font: "Helvetica", auto_grid: true, grid_lines: 3, label_radius: 1.10,
          default: "skip", chart: "radar", column_settings: @dimensions
      end
    end
    @grf.add values: @pre_test, color: blue, 
      name: "Pre-Test Score", min: 0, max: 100, strokewidth: 3
    cs = app.chart_series values: @practice, color: red,
      name: "Practice Score", min: 0, max: 100, strokewidth: 3
    @grf.add cs
    @grf.add values: @post_test, color: orange,
      name: "Post-Test Score", min: 0, max: 100, strokewidth: 3
  end
end
```

Lets look at that [it's gr7.rb](https://github.com/Shoes3/shoes3/blob/master/Tests/plot/gr7.rb) from the bottom up. We add three data series to the plot in @grf,  each with options we've seen before. Nothing new there. Scan up to creating the plot (our @grf). `chart: "radar"` - no surprise. `column_settings: @dimensions` @dimensions is the array of arrays that does this:

![radar-9](https://cloud.githubusercontent.com/assets/222691/20377785/07fb7878-ac4f-11e6-8af1-908c9d2b7953.png)

Look hard and you will notice we did not tell the plot widget (@grf) what the x-axis labels are? If dataseries are thought of as rows across a spreadsheet or database, then Shoes need column information and a lot more of it than other chart types.  That's column_settings:

It's an array of (you guessed it) a column setting and each of those can be an array or hash as demonstrated
as an array its ["label", min_column_value, max_column_value, and an _optional_ format string]. In that order if using an array. I'm going to describe them below using the hash name. 

#### label

This is the string drawn that is drawn around the outer part of the radar. 

#### min

Since the radial line for all data_series starts at the center you can control what this radial thinks is the minimum value for the center. 

#### max

Since the radial line for all data_series starts at the center and draw towards the outer edge you can control what this radial thinks is the maximum value for the outer edge. 

#### format

This is a Ruby printf formatting string. Be careful. It has to accept a Ruby float/double argument. The default is "%4.2f" which is four digits to the left of the decimal point and two digits to the right of it. The default is probably not what you want.

### other options to a plot radar chart. 

Shoes checks if all column minimums settings are the same number, and if all column maximum settings and if both are true then it only draws internal labels on the first (vertical) radial.  If not true you get a bunch of labels. See [gr6.rb](github.com/Shoes3/shoes3/blob/master/Tests/plot/gr6.rb)

#### grid_lines:

Shoes makes a guess at how many internal labels and y-axis 'rings' to draw. This is your place to tell Shoes how many you want. The argument of grid_line: is a little odd because it can be `true`, `false` or an integer number. False or 0 means you don't want any. True or 1 means you want Shoes to guess (the default). 2,3,4,5... means you want exactly that many. 

#### label_radius:

Depending on your data and settings and the size of the drawing space, Shoes does not always draw the outer (x axis) labels as closely to the edge as you want. label_radius: is a multiplier. The default 1.15. Setting it to 1.0 would draw on top of the outermost 'ring'  1.2 will probably collide with the plot title. Values less than 1.0 (say 0.5) works too but will probably confuse you and clutter up the chart.


## Beware

Plots are drawn with C code and it's not likely Shoes can detect all the ways your data and your calls don't make sense and can't be drawn or give you a nice error message. We try too but sometimes your going to get a segfault.

Testing github anchors [Radar Charts](#radar-charts)


