# ihy-mode
Hy inferior mode repl support 

# Installation:

```
pip3 install inim
```

# Obligatory gif -- WIP 

<!-- ![image info](/img/repl.gif) -->



I highly recommend using the straight package manager

```
(straight-use-package
 '(ihy
   :type git
   :host github
   :repo "serialdev/ihy-mode"
))
```

Alternatively pull the repo and add to your init file
```
git clone https://github.com/SerialDev/ihy-mode
```

## Hard Requirements
Ihy is required 


# Current functionality:

```
C-c C-p [Start repl]
C-c C-b [Eval buffer]
C-c C-l [Eval line]
C-c C-r [eval region]
C-c C-s [eval last sexp]
```

