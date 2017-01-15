As an alternative "widget", a customisable popup/tooltip like

```ruby
# encoding: UTF-8

module PopOver
    
    def pop_over(msg='', pwidth=400)
        @pwidth = pwidth
        # we need room around the shadow effect 
        @offset = 50
        
        pop_slot = stack width: @pwidth, height: 200 do
            image width: @pwidth, height: 200 do
                rect @offset, @offset, (@pwidth-@offset*2), 100, curve: 15, fill: rgb(0,0,0,0.4), stroke: rgb(0,0,0,0)
                shadow radius: 10, distance: 10, fill: rgb(0,0,0,0.8)
            end
            background rgb(255,255,255,0.5), curve: 15, width: (@pwidth-@offset*2-1), height: 99, left: @offset, top: @offset
            background rgb(255,0,255,0.5), curve: 15, width: (@pwidth-@offset*2-3), height: 97, left: @offset+2, top: @offset+2
            
            para msg, left: @offset+10, top: @offset+10, width: @pwidth-@offset*2-10
        end
        
        pop_slot.instance_eval %{
            def slide(x,y)
                move(x-#{@offset}, y-#{@offset})
                self
            end
            def tip=(tp)
                contents[3].text = tp 
            end
            def back_color=(pattern)
                contents[2].fill = pattern
                refresh_slot
            end
        }
        
        pop_slot
    end
end

Shoes.app title: "By letting go it all gets done.", width: 550, height: 300 do
    extend PopOver
    
    TIPS = [
        "People who think they know everything are a great annoyance to those of us who do.",
        "Stop thinking, and end your problems.",
        "To attain knowledge, add things everyday. To attain wisdom, remove things every day.",
        "One can laugh about anything but not with everybody.",
        "Step in someone's Shoes, a thousand miles before judging him.'"
    ]
    @mx = @my = 0
    motion { |x,y| @mx = x; @my = y }
    
    stack do
        caption "With great Wiseness comes great Responsibilities", align: "center"
        flow width:400 , margin: [25,25,0,10] do
            background darkorange, curve: 10; border red, curve: 10, strokewidth: 2
            para "Teach me !", margin_top: 10
            
            wiseness = 0
            hover { 
                @pop.slide(@mx, @my)
                if wiseness < 6
                    @pop.tip = TIPS[rand(TIPS.size)]
                elsif wiseness == 7
                    @pop.back_color = rgb(40,40,40,0.3)
                    @pop.tip = "\n\n\t\t\t\tI'm tired now ..."
                elsif wiseness > 9
                    @pop.back_color = red
                    @pop.tip = "Void, Nil, Zilch, not even Nada  !!\n\n\t\t\tGet It ?!?"
                end
                wiseness += 1
            }
            leave { @pop.slide @mx-1000, @my-1000 }
        end
        edit_line " Inspiring void, here ", margin: [25,5,0,15]
        para "-->  Pure Nothingness you might see  <--", stroke: green, margin_left: 25
        
        start { @pop = pop_over.slide @mx-1000, @my-1000 }
    end
end
```
