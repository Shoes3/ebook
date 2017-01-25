## Of Shoes::Widget and Shoes::Canvas

There is 4 kinds of slot in Shoes :
- flow   a class **Shoes::Types::Flow** (or Shoes::Flow : aliased to be the same)
- stack  a class **Shoes::Types::Stack** (Shoes::Stack)
- widget a class **Shoes::Types::Widget** (Shoes::Widget)
- mask   a class **Shoes::Types::Mask** (Shoes::Mask)

All of them are ultimately a **Shoes::Canvas** class. (Dark Woodoo subclassing, happening in C code around line 4585 in shoes/ruby.c, for the curious).

*We are going, for simplicity sake, to completely forget about Mask from now on and focus on Widget.*

All of them are exactly the same thing, a **Shoes::Canvas**, which in Shoes is called a **Slot**, they differ only by behaviour and are settled in a different class for clarity and of course for you to choose the right one depending on the intent : you want elements to pile, go for a stack, you want elements to line up choose a flow. (yes in terms of behaviour there is only two slots, more later...)

Let's look at some code to illustrate what follows (the log windows overlaps the Shoes window, it's there, just behind)

```ruby
Shoes.app width: 650, height: 200 do
    background gray
    para "hi"

    info "app = #{app.inspect} and app == self ? : #{app == self}"
    info "app.slot is_a? Shoes::Canvas : #{app.slot.is_a? Shoes::Canvas}"

    Shoes.show_log
end
```
prints :

```
app = (Shoes::Types::App "Shoes") and app == self ? : true
app.slot is_a? Shoes::Canvas : true
```

Bear with me, it's dead simple, just ~~hard~~ awful to write it down :

**app** inside the Shoes.app block is an instance method of Shoes::Canvas class returning the instance of **Shoes::Types::App** class, created by the *Shoes.app* class method ...

Okaaaay ! What's going on ?

All drawings in Shoes are happening on a Shoes::Canvas : everything you see is rendered on a Shoes::Canvas (gross oversimplification but that's not relevant here, let's just pretend), in the code above there is no slot declared, but, if you run the code, you can see the background and the para, that's because Shoes under the hood is building one slot automatically for you, and that one slot is accessible via the **slot** method of the App instance. It's the root of all the Shoes layout you are going to build.

Think about a Shoes::App as an abstraction layer above a Shoes::Canvas, in other words a Shoes::App is a bit more than a Shoes::Canvas, so in order to work with the App instance drawing abilities you need to specify which part of it you want to deal with and that part is what is returned from the slot method : a Shoes::Canvas  
This is all happening transparently and under normal circumstances you'll never have to deal with it, just know there is a default slot there, you can draw on without further ado.

Back to flows and stacks a bit to complete the setting :

I said they only differ in behaviour : under the cover, a default Shoes::Canvas is a Shoes::Flow, Shoes is doing some amazing placement processings there (look up for **shoes_place_decide** method and friends in shoes/ruby.c, make yourself comfortable before !).   
So if you let Shoes do it's stuff or summon a Shoes::Flow explicitely via **flow** method that's what you get : a default slot.  
If you decide to go the **stack** route then Shoes is "simply" changing it's placement calculations accordingly.


Now what is a widget ? Tadaaa ! You guessed it : a default slot, a Shoes::Flow, a Shoes::Canvas.  
More exactly, that Shoes::Canvas is what is returned by the dynamically build convenience method of the Shoes::Widget class : in the present example *test_widget()* whose name is derived from *TestWidget*   
***
**test_widget** method name is build from **TestWidget** class name,   
like so : **CamelCaseExampleWidget** to **camel_case_example_widget**   
It's a factory method : you don't call new on the class, i.e. TestWidget.new(arguments), but you call **test_widget(arguments)** to initialize the widget. This is consistent with edit_line, edit_box, etc...   
***

   
See code below, run it once, then comment test_widget line, uncomment flow block, run it again.   
Observe log window output.

Both app are exactly the same.

```ruby
class TestWidget < Shoes::Widget
    def initialize()
        self.width = 300; self.height = 150
        background gray
        para "hi"
    end
end

Shoes.app width: 650, height: 200 do
    test_widget
#    flow width: 300, height: 150 do
#        background gray
#        para "hi"
#    end

    info "app == self : #{self == app}"
    info "app.slot is_a? Shoes::Canvas : #{app.slot.is_a? Shoes::Canvas}"
    info "app.slot contents : #{app.slot.contents}"
    info "test_widget/flow is_a? Shoes::Canvas : #{app.slot.contents[0].is_a? Shoes::Canvas}"
    info "test_widget/flow contents : #{app.slot.contents[0].contents}"
    Shoes.show_log
end
```

In your scripts treat that mysterious Shoes::Widget for exactly what it is : a Slot, a Shoes::Flow

Note that inside the Shoes::Widget subclass (TestWidget here) **self**, thanks to the subclassing mechanism, ultimately looks like it is that slot itself, allowing you to tailor it the way you want like you would by means of styles inside the Shoes.app block.

As a reminder the main benefit of a widget is that you can reuse it at will in your actual script or later, if you save it to a file, in a totally different script.

  
### Let's build a simple widget : a check with some text
```ruby
class CheckText < Shoes::Widget
    def initialize(text, active=true)
        check checked: active
        para text
    end
end

Shoes.app width: 360, height: 200 do
    check_text "sure"
    check_text "no, please", false
    check_text "count me in", true
end
```
![checktext1](https://github.com/passenger94/shoes3/blob/wiki_images/checktext1.jpg)

Wait ! Here we are supposed to work only with Flows right ? : Widget's inside the app one !
Shouldn't we have check buttons lining up, instead of piling like in a Stack ?

See ! if we add a border to the widget : yes Flows ! as they have no specified width they occupy the maximum of available space and end up piling in the app Flow !

![checktext2](https://github.com/passenger94/shoes3/blob/wiki_images/checktext2.jpg)

Shall we add some width then ?
```ruby
class CheckText < Shoes::Widget
    def initialize(text, options={})
        self.width = options[:ct_width] || 120
        activ = options[:active] || false
        
        check checked: activ
        para text
    end
end

Shoes.app width: 360, height: 200 do
    check_text "sure", active: true, ct_width: 80
    check_text "no, please"
    check_text "count me in", active: true
end
```
![checktext3](https://github.com/passenger94/shoes3/blob/wiki_images/checktext3.jpg)

Voila ! Flows inside a Flow !

Nothing stops you from adding stacks and flows at will like inside the block app. You can add any kind of fine grained control over the widget, for example : font, background color, margins to name a few, you have all the Shoes Toolkit at hand baked by Ruby's extravaganza !

### Beware with events

If you use click, release, hover, leave events directly on the default slot of the widget, you could get surprised by what's going on.
```ruby
class TestWidget < Shoes::Widget
    def initialize()
        self.width = 300; self.height = 150
        background gray
        click { info "clicked" }
        hover { info "hovering" }
    end
end

Shoes.app width: 650, height: 200 do
    test_widget
end
```
Oooops ! Nothing ! No events, that's because, even though you provided some size to the Widget, in the perspective of the event mechanism there is no Thickness to the slot, hence no active surface to react to events.   
If you add, say a para, to the default slot it gives "some" Thickness to it and you're going to get "some" active area but likely not the entirety of the slot, just the part the para is filling.   
To workaround this, just make sure to wrap your code inside an "explicit" slot, which is going to bring proper Thickness to the widget.
```ruby
class TestWidget < Shoes::Widget
    def initialize()
        ## self.width = 300; self.height = 150 ## note that you might not need this anymore
        flow width: 300, height: 150 do   ###### explicit slot
            background gray
            click { info "clicked" }
            hover { info "hovering" }
        end                               ######
    end
end

Shoes.app width: 650, height: 200 do
    test_widget
end
```
(open the log console, Alt + / or ⌘ + / , if you happen to run the examples)
