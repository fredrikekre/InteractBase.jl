"""
```
dropdown(options::Associative;
         value = first(values(options)),
         label = nothing,
         multiple = false)
```

A dropdown menu whose item labels will be the keys of options.
If `multiple=true` the observable will hold an array containing the values
of all selected items
e.g. `dropdown(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`
"""
function dropdown(::WidgetTheme, options::Associative;
    attributes=PropDict(),
    label = nothing,
    multiple = false,
    value = multiple ? valtype(options)[] : first(values(options)),
    class = nothing,
    className = _replace_className(class),
    style = PropDict(),
    outer = vbox,
    div_select = dom"div.select",
    kwargs...)

    style = _replace_style(style)
    multiple && (attributes[:multiple] = true)

    (value isa Observable) || (value = Observable{Any}(value))
    isnumeric = (valtype(options) <: Number) && !(valtype(options) <: Bool)
    bind = multiple ? "selectedOptions" : "value"
    option_array = [OrderedDict("key" => key, "val" => val) for (key, val) in options]
    s = gensym()
    attrDict = merge(
        Dict(Symbol("data-bind") => "options : options, $bind : value, optionsText: 'key', optionsValue: 'val'"),
        attributes
    )

    className = mergeclasses(getclass(:dropdown), className)
    template = Node(:select; className = className, attributes = attrDict, kwargs...)() |> div_select
    label != nothing && (template = outer(template, wdglabel(label)))
    ui = knockout(template, ["value" => value, "options" => option_array]);
    slap_design!(ui)
    Widget{:dropdown}(ui, "value") |> wrapfield
end

"""
`dropdown(values::AbstractArray; kwargs...)`

`dropdown` with labels `string.(values)`
see `dropdown(options::Associative; ...)` for more details
"""
dropdown(T::WidgetTheme, vals::AbstractArray; kwargs...) =
    dropdown(T, OrderedDict(zip(string.(vals), vals)); kwargs...)

"""
```
radiobuttons(options::Associative;
             value::Union{T, Observable} = first(values(options)))
```

e.g. `radiobuttons(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`
"""
function radiobuttons(T::WidgetTheme, options::Associative; label = nothing,
    value = first(values(options)), kwargs...)

    (value isa Observable) || (value = Observable{Any}(value))
    vmodel = isa(value[], Number)  ? "v-model.number" : "v-model"

    s = gensym()
    option_array = [OrderedDict("key" => key, "val" => val, "id" => "id"*randstring()) for (key, val) in options]
    radio = InteractBase.radio(s, kwargs...)
    (radio isa Tuple )|| (radio = (radio,))
    template = Node(:div, className=getclass(:radiobuttons), attributes = "data-bind" => "foreach : options")(
        radio...
    )
    ui = knockout(template, ["value" => value, "options" => option_array])
    (label != nothing) && (scope(ui).dom = flex_row(wdglabel(label), scope(ui).dom))
    slap_design!(ui)
    Widget{:radiobuttons}(ui, "value") |> wrapfield
end

"""
`radiobuttons(values::AbstractArray; kwargs...)`

`radiobuttons` with labels `string.(values)`
see `radiobuttons(options::Associative; ...)` for more details
"""
radiobuttons(T::WidgetTheme, vals::AbstractArray; kwargs...) =
    radiobuttons(T, OrderedDict(zip(string.(vals), vals)); kwargs...)

function radio(T::WidgetTheme, s; class=nothing, className=_replace_className(class), kwargs...)
    className = mergeclasses(getclass(:input, "radio"), className)
    (
        Node(:input, className = className, attributes = Dict("name" => s, "type" => "radio", "data-bind" => "checked : \$root.value, checkedValue: val, attr : {id : id}"))(),
        Node(:label, attributes = Dict("data-bind" => "text : key, attr : {for : id}"))
    )
end

for (wdg, tag, singlewdg, div) in zip([:togglebuttons, :tabs], [:button, :li], [:button, :tab], [:div, :ul])
    @eval begin
        function $wdg(T::WidgetTheme, options::Associative; tag = $(Expr(:quote, tag)),
            className = getclass($(Expr(:quote, singlewdg)), "fullwidth"),
            activeclass = getclass($(Expr(:quote, singlewdg)), "active"),
            value = medianelement(1:length(options)), label = nothing, kwargs...)


            index = isa(value, Observable) ? value : Observable(value)
            vals = collect(values(options))

            className = mergeclasses(getclass($(Expr(:quote, singlewdg))), className)

            btns = [Node(tag,
                         label,
                         attributes=Dict("key" => idx, "data-bind"=>
                            "click: => index($idx), css: {'$activeclass' : index() == $idx, '$className' : true}"),
                         ) for (idx, (label, val)) in enumerate(options)]

            template = Node($(Expr(:quote, div)), className = getclass($(Expr(:quote, wdg))))(
                btns...
            )
            # hack to avoid type error problems
            value = Observable{eltype(vals)}(vals[index[]])
            map!(i -> vals[i], value, index)
            label != nothing && (template = flex_row(wdglabel(label), template))
            ui = knockout(template, ["index" => index])
            slap_design!(ui)
            Widget{$(Expr(:quote, wdg))}(ui, value) |> wrapfield
        end
    end
end

"""
`togglebuttons(options::Associative; value::Union{T, Observable})`

Creates a set of toggle buttons whose labels will be the keys of options.
"""
function togglebuttons end

"""
`togglebuttons(values::AbstractArray; kwargs...)`

`togglebuttons` with labels `string.(values)`
see `togglebuttons(options::Associative; ...)` for more details
"""
function togglebuttons(T::WidgetTheme, vals; kwargs...)
    togglebuttons(T::WidgetTheme, OrderedDict(zip(string.(vals), vals)); kwargs...)
end

function tabs end

function tabs(T::WidgetTheme, vals; kwargs...)
    tabs(T::WidgetTheme, OrderedDict(zip(vals, vals)); kwargs...)
end

"""
```
checkboxes(options::Associative;
         value = first(values(options)))
```

A list of checkboxes whose item labels will be the keys of options.
Tthe observable will hold an array containing the values
of all selected items,
e.g. `checkboxes(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`
"""
checkboxes(::WidgetTheme, options::Associative; kwargs...) =
    Widget{:checkboxes}(multiselect(gettheme(), options, "checkbox"; typ="checkbox", kwargs...))

"""
`checkboxes(values::AbstractArray; kwargs...)`

`checkboxes` with labels `string.(values)`
see `checkboxes(options::Associative; ...)` for more details
"""
checkboxes(T::WidgetTheme, vals; kwargs...) =
    checkboxes(T::WidgetTheme, OrderedDict(zip(string.(vals), vals)); kwargs...)

"""
```
toggles(options::Associative;
         value = first(values(options)))
```

A list of toggle switches whose item labels will be the keys of options.
Tthe observable will hold an array containing the values
of all selected items,
e.g. `toggles(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`
"""
toggles(::WidgetTheme, options::Associative; kwargs...) =
    Widget{:toggles}(multiselect(gettheme(), options, "toggle"; typ="checkbox", kwargs...))

"""
`toggles(values::AbstractArray; kwargs...)`

`toggles` with labels `string.(values)`
see `toggles(options::Associative; ...)` for more details
"""
toggles(T::WidgetTheme, vals; kwargs...) =
    toggles(T::WidgetTheme, OrderedDict(zip(string.(vals), vals)); kwargs...)

function multiselect(::WidgetTheme, options::Associative, style; label=nothing, vskip=0em,
    outer = dom"div", value = valtype(options)[], entry=InteractBase.entry, kwargs...)

    (value isa Observable) || (value = Observable(value))

    vals = collect(values(options))
    template = outer(
        (InteractBase.entry(gettheme(), style, label, vals[idx]; kwargs...)
            for (idx, (label, _)) in enumerate(options))...
    )
    ui = knockout(template, ["value"=> value])
    (label != nothing) && (scope(ui).dom = vbox(wdglabel(label), CSSUtil.vskip(vskip), scope(ui).dom))
    slap_design!(ui)
    Widget{:multiselect}(ui, "value")
end

function entry(::WidgetTheme, wdgtyp, label, val; typ="checkbox", class=nothing, className=_replace_className(class),
    outer=dom"div.field", attributes=PropDict(), style=PropDict(), kwargs...)

    className = mergeclasses(getclass(:input, wdgtyp), className)
    s = string(gensym())
    outer(
        dom"input[type=$typ]"(;
            className = className,
            attributes = merge(attributes, Dict("value" => val,
                                                "id" => s,
                                                "data-bind" => "checked : value")),
            style = _replace_style(style)),
        dom"label[for=$s]"(label)
    ) |> wrapfield
end

function _mask(key, keyvals, values; display = "block")
    s = string(gensym())
    onjs(key, js"""
        function (k) {
            var options = document.getElementById($s).childNodes;
            for (var i=0; i < options.length; i++) {
                options[i].style.display = (options[i].getAttribute('key') ==  String(k)) ? $display : 'none';
            }
        }
    """)

    displays = [(keyval == key[]) ? "display:$display" : "display:none" for keyval in keyvals]

    dom"div[id=$s]"(
        (dom"div[key=$keyval, style=$displaystyle;]"(value) for (displaystyle, keyval, value) in zip(displays, keyvals, values))...
    )
end

function tabulator(options, values; value=1, display = "block", vskip = 1em)

    buttons = togglebuttons(options; value=value)
    key = buttons["index"]
    keyvals = 1:length(options)

    content = _mask(key, keyvals, values; display=display)

    ui = vbox(buttons, CSSUtil.vskip(vskip), content)
    Widget{:tabulator}(ui, scope(buttons), key)
end

tabulator(pairs::Associative; kwargs...) = tabulator(collect(keys(pairs)), collect(values(pairs)); kwargs...)
