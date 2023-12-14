Scale:=2.00;
MagDecl:=2.73;
GridConv:=-2.06;
string OutputColormodel;
OutputColormodel:="cmyk";
verbatimtex \input th_enc.tex etex;
%% therion source code
%%
%% therion.mp
%%
%% This file defines low-level MetaPost macros and variables required
%% for generation of map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: therion.mp,v $
%% $Revision: 1.3 $
%%
%% Copyright (C) 2000-2003 Martin Budaj
%%
%% Some macros are adapted from MPATTERN package of P. Bolek
%%
%% Some macros are used from MetaFun package of H. Hagen
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

%    This file defines low level macros used for map signatures in Therion.
%    Before loading this file set `Scale' variable to numeric value
%    representing denominator of the scale ratio. Internal variable
%    `prologues' is set to 1 by this file. This module loads also
%    symbol libraries.

if unknown mpversion: string mpversion; mpversion := "0.0"; fi
if scantokens(mpversion) < 1.0:
  errmessage "MetaPost 1.0 or later required";
fi

tracingstats:=1;
prologues:=0;

% Set the random seed to a fixed value so therion reproducibly produces the
% same output for a given input.
randomseed:=42;

if known Background: background:=Background fi;
%TrueScale:=Scale;

% @VARIABLE
% symbol_scale --
%
% <I>internal numeric</I>; in map symbol definitions used for scaling
% in <A HREF="#T">T</A> transformation; recommended
% values are 1 or 2.

%newinternal symbol_scale;
%symbol_scale := 1;

% @VARIABLE
% fill_only --
%
% <I>boolean</I>, used in <A HREF="#thdraw">thdraw</A> and
% <A HREF="#thpattfill">thpattfill</A> commands. When set to false, it has
% no effect, when it is true, it suppresses all drawing
% commands with exception of <I>thpermanentfill</I>, so that only filled
% areas are drawn

boolean fill_only, horiz_labels, transparency;
fill_only := false;
horiz_labels:=true;
transparency:=false;

string ATTR__id, ATTR__survey, ATTR__scrap, NorthDir;
boolean ATTR__scrap_centerline;
picture ATTR__text;
numeric ATTR__height;
boolean ATTR__elevation;
ATTR__scrap_centerline := false;
ATTR__height:=0;
ATTR__elevation:=false;

boolean ATTR__shotflag_splay;
ATTR__shotflag_splay:=false;
boolean ATTR__shotflag_duplicate;
ATTR__shotflag_duplicate:=false;
boolean ATTR__shotflag_approx;
ATTR__shotflag_approx:=false;
boolean ATTR__stationflag_splay;
ATTR__stationflag_splay:=false;

save black, white, red, green, blue, background, HelpSymbolColor, tmpcol;
if OutputColormodel = "cmyk":
  cmykcolor black, white, red, green, blue, background, HelpSymbolColor, tmpcol;
  black := (0,0,0,1);
  white := (0,0,0,0);
  red   := (0,0.9,0.9,0.2);
  green := (0.7,0,0.8,0.4);
  blue  := (0.6,0.4,0,0.1);
  HelpSymbolColor := (0,0,0,0.2);
  defaultcolormodel := 7;
elseif OutputColormodel = "rgb":
  rgbcolor black, white, red, green, blue, background, HelpSymbolColor, tmpcol;
  black := (0,0,0);
  white := (1,1,1);
  red   := (1,0,0);
  green := (0,1,0);
  blue  := (0,0,1);
  HelpSymbolColor := (0.8,0.8,0.8);
  defaultcolormodel := 5;
else:
  black := 0;
  white := 1;
  red   := 0.3;
  green := 0.59;
  blue  := 0.11;
  HelpSymbolColor := 0.8;
  defaultcolormodel := 3;
fi;
background = white;

string includeprefix;
includeprefix = ".";
def inputrel(expr p) =
  scantokens("input " & includeprefix & p);
enddef;

vardef fixminus (expr s) =   % used for numbers formatted as strings to use "--" as a minus symbol
  if substring (0,1) of s = "-": "-" & s
  else: s
  fi
enddef;

color label_fill_color, label_fill_color_tmp;
label_fill_color := (1.0, 1.0, 1.0);
def push_label_fill_color(expr r,g,b) =
  label_fill_color_tmp := label_fill_color;
  label_fill_color := (r,g,b);
enddef;
def pop_label_fill_color =
  label_fill_color := label_fill_color_tmp;
enddef;
def process_filledlabel(expr cent, rot) =
  begingroup;
    interim bboxmargin:=2.0bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    fill q withcolor label_fill_color;
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;




numeric area_border_errors;
area_border_errors = 0;

% @VARIABLE
% last_write --
%
% <I>numeric</I>; charcode of last figure which contained
% <A HREF="#write_bbox">write_bbox</A> macro; this value is used by
% <A HREF="#close_file">close_file</A> macro. Initially set to -1.

numeric last_write;
last_write = -1;

% @VARIABLE
% file_name --
%
% <I>string</I>, name of file, where <I>write_bbox</I> macro writes
% text clipping path

% @VARIABLE
% s ch --
%
% <I>string</I>, temporary string/char variables

string s, ch, file_name, bg_name, clip_name, lang, diff_pos, diff_neg,
     current_scrap, current_src;

% @VARIABLE
% u v w --
%
% <I>internal numeric variables</I> used as basic length units for drawing;
% they are set by <A HREF="#initialize">initialize</A> macro.
% <UL> <LI><I>u</I> -- normal unit decreasing with increasing scale
%      <LI><I>v</I> -- like <I>u</I>, but can increase drammaticaly
%            when some limit is encountered (to get effects like logarithmic
%            scale)
%      <LI><I>w</I> -- nearly constant at all scales
% </UL>

% @VARIABLE
% legend_scale --
%
% <I>numeric</I>, length of the longer side of signatures' legend box

newinternal legend_scale, u,v,w;

% @VARIABLE
% lab Lab --
%
% <I>picture</I>, in which are saved typeset labels

picture lab, Lab;

% @VARIABLE
% T --
%
% <I>transformation</I>, defines transformation function for transforming
% every argument of <A HREF="#thdraw>thdraw</A> and <A HREF="#thfill>thfill</A>
% macros

transform T;

% @VARIABLE
% p,q --
%
% <I>path</I>, for saving temporary paths

path p,q;

% @MACRO
% initialize --
%
% initializes basic length units <A HREF="#u">(u,v,w)</A> and pens used
% in map symbols according to scale. Five circular pens are defined:
% <UL><LI>PenA -- thick; for outlines
%    <LI>PenB, PenC -- thinner; for pits, symbols etc.
%    <LI>PenD -- thinnest; for fine details
%    <LI>PenX -- extra thick; not recommended for use
% </UL>

def fonts_setup (expr t,s,m,l,h) =
  write "\def\updown#1#2{\vbox{" &
        "\offinterlineskip" &
        "\setbox100=\hbox{#1}" &
        "\setbox101=\hbox{#2}" &
        "\ifnum\wd100>\wd101\hsize=\wd100\else\hsize=\wd101\fi" &
        "\centerline{\box100}\vskip4pt" &
        "\centerline{\box101}}}" &
        "\def\thlabel{\thnormalsize}" &
        "\def\thremark{\thsmallsize\si}" &
        "\def\thcomment{\thsmallsize}" &
        "\def\thentrance{\thsmallsize}" &
        "\def\thaltitude{\thsmallsize}" &
        "\def\thstationname{\thsmallsize}" &
        "\def\thdate{\thsmallsize}" &
        "\def\thheight{\thsmallsize}" &
        "\def\thheightpos{+\ignorespaces}" &
        "\def\thheightneg{-\ignorespaces}" &
        "\def\thframed{\thsmallsize}" &
        "\def\thwallaltitude{\thtinysize}"
  to "mptexpre.tex";
  write "\newcount\basefontsize" &
        "\def\thtinysize{\size[" & decimal max(optical_zoom*t,0) & "]\basefontsize=" & decimal round max(optical_zoom*t,0) & "}" &
        "\def\thsmallsize{\size[" & decimal max(optical_zoom*s,0) & "]\basefontsize=" & decimal round max(optical_zoom*s,0) & "}" &
        "\def\thnormalsize{\size[" & decimal max(optical_zoom*m,0) & "]\basefontsize=" & decimal round max(optical_zoom*m,0) & "}" &
        "\def\thlargesize{\size[" & decimal max(optical_zoom*l,0) & "]\basefontsize=" & decimal round max(optical_zoom*l,0) & "}" &
        "\def\thhugesize{\size[" & decimal max(optical_zoom*h,0) & "]\basefontsize=" & decimal round max(optical_zoom*h,0) & "}"
  to "mptexpre.tex";
  write EOF to "mptexpre.tex";
enddef;

def initialize (expr sc) =

  if unknown BaseScale: BaseScale = sc; fi;
  optical_zoom := BaseScale/sc;

    if BaseScale <= 1:                   % 1:100
        u:=14bp; v:=14bp; w:=12bp;
        fonts_setup(8,10,12,16,24);
    elseif BaseScale <= 2:               % 1:200
        u:=12bp; v:=12bp; w:=12bp;
        fonts_setup(7,8,10,14,20);
    elseif BaseScale <= 5:               % 1:500
        u:=10bp; v:=10bp; w:=12bp;
        fonts_setup(6,7,8,10,14);
    else:
        u:=7bp; v:=14bp; w:=10bp;
        fonts_setup(5,6,7,8,10);
    fi;

    u := optical_zoom * u;
    v := optical_zoom * v;
    w := optical_zoom * w;

    defaultscale := 0.8 * optical_zoom;

    def PenA = pencircle scaled (u/10) enddef;
    def PenB = pencircle scaled (0.7*u/10) enddef;
    def PenC = pencircle scaled (0.5*u/10) enddef;
    def PenD = pencircle scaled (0.35*u/10) enddef;
    def PenX = pencircle scaled (1.2*u/10) enddef;

    legend_scale := 3.14*u;
enddef;

% macro is expanded, we have to know all dimensions and pens before reading
% mpattern macros

initialize(Scale);

vardef thTEX primary s =
  write "verbatimtex \input th_enc.tex etex" to "mptextmp.mp";
  write "btex \mainfont "&s&" etex" to "mptextmp.mp";
  write EOF to "mptextmp.mp";
  scantokens "input mptextmp"
enddef;

% @MACRO
% inscale --
%
% zooms objects to scale specified in legend_scale variable (used in legend
% typesetting)

def inscale =
    xscaled legend_scale yscaled (0.618*legend_scale)
enddef;

% @MACRO
% draw_legend_box --
%
% draws a legend bounding box and resets drawoptions() options

def draw_legend_box =
    clip currentpicture to unitsquare inscale;
    drawoptions();
    pickup PenB;
    draw unitsquare inscale;
enddef;

def clean_legend_box =
  unfill unitsquare inscale;
enddef;

def legend_point (expr name) =
%  if substring (2,9) of name = "station":
%    scantokens(name)((0.5,0.5) inscale);
%  else:
    scantokens(name)((0.5,0.5) inscale,0,1,(0,0));
%  fi;
  draw_legend_box;
enddef;

def legend_line (expr name) =
  scantokens(name)((((-0.3,.5)..(.3,.7)..(.5,.3)..{dir 80}(1.3,.9)) inscale)
                randomized 3mm);
  draw_legend_box;
enddef;

% legend_label
% legend_area
% legend_random

% @MACRO
% roundone --
%
% rounds <I>numeric value</I> to one decimal point

vardef roundone(expr n) =
%    round(10*n)/10
  n
enddef;

% @MACRO
% process_label --
%
% draws a label saved in <I>lab</I> picture variable and calls
% <A HREF="#write_bbox">write_bbox</A> macro.


def process_label (expr cent, rot) =
  begingroup;
    interim bboxmargin:=0.8bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;

% @MACRO
% process_uplabel --
%
% draws a label into semicircular box and writes clipping path to a file

def process_uplabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=.8-.02*(xpart lrcorner q - xpart llcorner q);
%    show alef;
    q:=alef[llcorner q,ulcorner q]{up} .. {down}alef[lrcorner q, urcorner q] --
        lrcorner q -- llcorner q -- cycle;
    draw lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_downlabel --
%
% draws a label into down oriented semicircular box and writes
% clipping path to a file

def process_downlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=1-(.8-.02*(xpart lrcorner q - xpart llcorner q));
    q:=alef[llcorner q,ulcorner q]{down} ..
        {up}alef[lrcorner q, urcorner q] --
        urcorner q -- ulcorner q -- cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_updownlabel --
%
% draws a label split into down and up oriented semicircular boxes and
% writes clipping path to a file

def process_updownlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    p:=bbox lab;
  endgroup;
    leftside:=xpart llcorner p;
    rightside:=xpart lrcorner p;
    draw (xpart llcorner p,.5[ypart llcorner p,ypart ulcorner p]) --
         (xpart lrcorner p,.5[ypart llcorner p,ypart ulcorner p]);
    alef:=1.05-.02*(xpart lrcorner p - xpart llcorner p);
%    alef:=.8-.02*(rightside-leftside);
    p:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} ..
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner p), (rightside, ypart lrcorner p)]{down}
        .. {up}alef[(leftside, ypart ulcorner p),(leftside, ypart llcorner p)]
        -- cycle;
%    p:=alef[llcorner p,ulcorner p]{up} .. {down}alef[lrcorner p, urcorner p] --
%        aleff[llcorner p,ulcorner p]{down} ..
%        {up}aleff[lrcorner p, urcorner p] -- cycle;
    draw lab;
    draw p;
    p:=reverse p;
    write_circ_bbox(p);
enddef;

def process_updownlabel_OLD =
    p:=bbox lab;
    q:=bbox Lab;
    leftside:=min(xpart llcorner p, xpart ulcorner q);
    rightside:=max(xpart lrcorner p, xpart urcorner q);
    draw .5[(leftside, ypart llcorner p),(leftside, ypart ulcorner q)] --
         .5[(rightside,ypart lrcorner p),(rightside,ypart urcorner q)];
    alef:=.8-.02*(rightside-leftside);
    q:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} ..
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner q), (rightside, ypart lrcorner q)]{down}
        .. {up}alef[(leftside, ypart ulcorner q),(leftside, ypart llcorner q)]
        -- cycle;
    draw lab;
    draw Lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_boxedlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_boxedlabel =
  begingroup;
    interim bboxmargin:=1.0bp;
    q:=bbox lab;
    draw lab;
    draw q;
    write_bbox(q);
  endgroup;
enddef;

% @MACRO
% process_circledlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_circledlabel =
  begingroup;
    interim bboxmargin := 0.4 bp;
    q:=bbox lab;
  endgroup;
    q:=point 0 of q .. point 1 of q .. point 2 of q .. point 3 of q .. cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;


% @MACRO
% write_bbox --
%
% Arguments:
%   <I>path</I> variable -- rectangular bounding box of a label;
%   assumptions: path is cyclic, counterclockwise oriented, with four points,
%   composed from linear segments;
%   see general <A HREF="#write_circ_bbox">write_circ_bbox</A> macro
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf
%   format

def write_bbox (expr q) =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    for i:=4 downto 0:
        s  :=  decimal(roundone(xpart point i of q)) & " "
             & decimal(roundone(ypart point i of q))
             & if i=4: " m " else: " l" fi;
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% write_circ_bbox --
%
% Arguments:
%   <I>path</I> variable, only assumption is that <I>path</I> is cyclic
%   and counterclockwise oriented.
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf
%   format

def write_circ_bbox expr q =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    tmp:=length q;
    s :=  decimal(roundone(xpart point tmp of q)) & " "
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s to file_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " "
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " "
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " "
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% close_file --
%
% closes file with a clipping path; it's invoked by <I>endchar</I> macro

def close_file =
    if last_write=charcode:
        write EOF to jobname & "." & decimal(charcode) & "bbox";
    fi;
enddef;

% endchar should run close_file macro

extra_endfig := "close_file;";

% @MACRO
% thdraw --
%
% like plain MetaPost's <I>draw</I>, but draws a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% (If <I>fill_only=false</I>)

def thdrawoptions(text t) =
  def _thop_ = t enddef
enddef;
thdrawoptions();

def thdraw expr p =
  if not fill_only:
    addto currentpicture
    if picture p:
      also (p transformed T)
    else:
      doublepath (p transformed T) withpen currentpen
    fi
    _thop_  _op_
  else:
    addto currentpicture also nullpicture
  fi
enddef;

% @MACRO
% thfill --
%
% fills a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% Filled areas are clipped (like most
% other lines and points) with a clipping path around text labels.


def thfill expr c =
    addto currentpicture contour (c transformed T) _thop_ _op_
enddef;

def thfilldraw expr c =
  if not fill_only:
    addto currentpicture contour (c transformed T) withpen currentpen _thop_ _op_
  else:
    addto currentpicture contour (c transformed T) _thop_ _op_
  fi
enddef;

def thunfill expr c =
    thfill c withcolor background
enddef;

def thundraw expr p =
    thdraw p withcolor background
enddef;

def thunfilldraw expr c =
    thfilldraw c withcolor background
enddef;

def thclean expr c =
  if transparency:
    thfill c withcolor background withalpha -1
  else:
    thunfill c
  fi;
enddef;

def thPatternFill (expr Path, Pattern) =
  T:=identity;
  thclean Path;
  thfill Path withpattern Pattern;
enddef;

%def thLegendPatternFill (expr Path, Pattern) =
%  T:=identity;
%  thfill Path withpattern Pattern;
%enddef;

% for drawarrow:

def _finarr text t =
  thdraw _apth t;
  thfilldraw arrowhead _apth  t
enddef;

% @MACRO
% thpermanentfill --
%
% Fills specified area with a solid color; this area is not affected by
% text clipping path

%def thpermanentfill expr c =
%    addto currentpicture contour (c transformed T) _thop_ _op_
%enddef;

let thpermanentfill = thfill;


primarydef p aligned al=
  p shifted (xpart al * xpart U, ypart al * ypart U)
enddef;

% macros for drawing scraps in upper and lower levels; filled lower scraps
% require special treatment (MetaPost doesn't support non-continuous paths).
% We can't use one file for both, while PDF XObject has to be explicitly
% filled or stroked. Second macro writes also pseudo-pdf code of a clipping
% path for given scrap

boolean drawnext;
drawnext:=true;

def draw_upscrap (expr isout)(text t) =
  path q;
  for i=t:
    if (numeric i):
      if (i=1): drawnext:=true; else: drawnext:=false; fi;
    else:
      if drawnext: draw i withpen PenD withoutcolor; fi;
      if not known q: q:=i; else: q:=q -- i; fi;
    fi;
  endfor;
  if not cycle q: q:=q -- cycle; fi;
  if turningnumber q = 0:
      thwarning("scrap outline intersects itself");
  fi;
  if isout=1:
    if turningnumber q > 0: q := reverse q; fi;
  else:
    if turningnumber q < 0: q := reverse q; fi;
  fi;
  addto bgfill contour q withoutcolor;
enddef;

% following macro writes noncontinuous PostScript path directly to EPS file
% (filled background and clipping path)

picture bgfill;
bgfill:=nullpicture;

def draw_downscrap =
  bg_name := jobname & "." & decimal(charcode) & "bg";
  clip_name := jobname & "." & decimal(charcode) & "clip";
  write "%!PS" to bg_name;
  write "%%BoundingBox: " &
     decimal floor xpart llcorner bgfill & " " &
     decimal floor ypart llcorner bgfill & " " &
     decimal ceiling xpart urcorner bgfill & " " &
     decimal ceiling ypart urcorner bgfill
     to bg_name;
  write "%%Page: 1 1" to bg_name;
  write "newpath" to bg_name;
  for qq within bgfill:
    q := pathpart qq;
    tmp:=length q;
    s := decimal(roundone(xpart point tmp of q)) & " "
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s & "oveto" to bg_name;
    write s to clip_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " "
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " "
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " "
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s & "urveto" to bg_name;
        write s to clip_name;
    endfor;
  endfor;
  write "closepath fill" to bg_name;
  write "showpage" to bg_name;
  write "%%EOF" to bg_name;
  write EOF to bg_name;
  write EOF to clip_name;
  bgfill:=nullpicture;
enddef;



vardef buildcycle(text ll) =
  save ta_, tb_, k_, i_, pp_; path pp_[];
  k_=0;
  for q=ll: pp_[incr k_]=q; endfor
  i_=k_;
  for i=1 upto k_:
    (ta_[i], length pp_[i_]-tb_[i_]) =
      pp_[i] intersectiontimes reverse pp_[i_];
    if ta_[i]<0:
      message("[Error: area borders "& area_border[i] &" and "&
         area_border[i_] &" don't intersect in scrap " & current_scrap &
         " (file " & current_src & ")]");
      area_border_errors := area_border_errors + 1;
    fi
    i_ := i;
  endfor
  for i=1 upto k_: subpath (ta_[i],tb_[i]) of pp_[i] .. endfor
    cycle
enddef;

vardef unitvector primary z =
  if (z<>(0,0)):
    z/abs z
  else:
    hide(thwarning("strange path"))
    (0,epsilon)
  fi
enddef;

def thwarning (expr m) =
  message("[Warning: " & m & " in scrap " & current_scrap & "]");
enddef;

def check_area_borders =
  if area_border_errors > 0:
  fi;
enddef;

%%%%%%%%%%%% Map symbols management %%%%%%%%%%%%%%%%%%%

def mapsymbol (expr name, set, warning) =
  string s, stype, lname, ID;
  stype = substring (0,1) of name;
  lname = name & "_" & set;
  ID := "ID_" & lname;
  if (known scantokens ID):
    if stype = "a":
      s = "def " & name & " = scantokens(" & ditto & lname & ditto & ") enddef;";
    else:
      s = "let " & name & " = " & lname & ";";
    fi;
    scantokens s;
  elseif warning:
    message("[Warning: undefined symbol `" & lname & "']");
  fi;
enddef;

%def hidesymbol (expr name) =
%  string s, stype;
%  stype = substring (0,1) of name;
%  if stype = "a":
%    s = "def " & name & " = scantokens(" & ditto & "a_empty" & ditto & ") enddef;";
%  else:
%    s = "vardef " & name & "@# (text t) = enddef;";
%  fi;
%  scantokens s;
%  write name to "missed.dat";
%enddef;

def initsymbol (expr name) =
  s := "ID_" & name & " = 1";
  scantokens s;
enddef;

%%%

% comment out groups in order to use 'save ATTR_*' appropriately

def beginfig(expr c) =
%  begingroup
  charcode:=c;
  clearxy; clearit; clearpen;
  pickup defaultpen;
  drawoptions();
  scantokens extra_beginfig;

  save smartll, smartur;
  pair smartll[], smartur[];
  smart_count := 0;
enddef;

def endfig =
  scantokens extra_endfig;
  shipit;
%  endgroup
enddef;

vardef tightbbox primary p =
  llcorner p -- lrcorner p -- urcorner p -- ulcorner p -- cycle
enddef;

% https://tug.org/pipermail/metapost/2008-February/001218.html
vardef log primary x =
     (if x=0: 0 else: mlog(x)/mlog(10) fi)
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% P. Bolek's MPATTERN package adapted and simplified for Therion
% (with the same user interface except of patterncolor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

string Pname_, PXYsteps_;
string Pmatrix_;

numeric Pnum_; Pnum_=0;
string Psuffix_; Psuffix_="-patt";

def PmakeBB_=
   PBBox_ := "[" & decimal Plft_ & " " & decimal Plow_ & " "
   & decimal Prt_ & " " & decimal Pup_ & "]";
enddef;

def Psteps_=
   PXYsteps_ := decimal
     if unknown PXStep_: (Prt_-Plft_) else: PXStep_ fi
   & ":" & decimal
     if unknown PYStep_: (Pup_-Plow_) else: PYStep_ fi;
enddef;

vardef Pfindbounds_=
   Plow_ = ypart (llcorner currentpicture);
   Plft_ = xpart (llcorner currentpicture);
   Pup_ = ypart (urcorner currentpicture);
   Prt_ = xpart (urcorner currentpicture);
   PmakeBB_;
enddef;

def PmakePattern_(expr name)=
  write Pname_ & ":"
    & jobname & Psuffix_ & "." & decimal charcode & ":"
    & PBBox_ & ":"
    & PXYsteps_ & ":"
    & Pmatrix_
  to "patterns.dat"
enddef;

% User interface macros

vardef patternbbox(expr a)(text b)=
   save Pi_, Pz_;
   numeric Pi_, Pz_[];
   if pair a:
      Plft_:=min(xpart(a),xpart(b)); Plow_:=min(ypart(a),ypart(b));
      Prt_:=max(xpart(a),xpart(b));  Pup_:=max(ypart(a),ypart(b));
   else:
      Pi_=1;
      for t=b:
	 Pz_[Pi_]=t;
	 Pi_:=Pi_+1;
      endfor;
      Plft_:=min(a,Pz_2);   Plow_:=min(Pz_1,Pz_3);
      Prt_:=max(a,Pz_2); Pup_:=max(Pz_1,Pz_3);
   fi;
   PmakeBB_;
enddef;

def beginpattern(suffix name)=
  numeric PXStep_, PYStep_;
  numeric Plow_, Plft_, Pup_, Prt_;
  string PBBox_;
  Pmatrix_:="[1 0 0 1 0 0]";
  Pname_:=str name;
  Pnum_:=Pnum_+1;
  outputtemplate := "%j"&Psuffix_&".%c";
  beginfig(Pnum_);
enddef;

def endpattern=
  if unknown PBBox_:
     Pfindbounds_;
  fi;
  endfig;
  Psteps_;
  PmakePattern_(Pname_);
  scantokens("string " & Pname_ & "; "&Pname_&"="&ditto&Pname_&ditto&";");
  outputtemplate := "%j.%c";
enddef;

picture pattpict;
string patterncolor_;
patterncolor_ := "0 0 0 1";

vardef colortostr(expr c, s) =
  hide(pattpict := image(draw (0,0)--(10,10) withcolor c);
    for i within pattpict:
      if colormodel i = 1:
        patterncolor_ := decimal greypart i;
      elseif colormodel i = 5:
        patterncolor_ := decimal redpart i & s & decimal greenpart i & s & decimal bluepart i;
      elseif colormodel i = 7:
        patterncolor_ := decimal cyanpart i & s & decimal magentapart i & s & decimal yellowpart i & s & decimal blackpart i;
      fi
    endfor;)
  patterncolor_
enddef;

primarydef p withpattern s=
  if known s:
    p
    hide(pattpict := image(draw (0,0)--(10,10));
      for i within pattpict:
        if colormodel i = 1:
          patterncolor_ := decimal greypart i;
        elseif colormodel i = 5:
          patterncolor_ := decimal redpart i & " " & decimal greenpart i & " " & decimal bluepart i;
        elseif colormodel i = 7:
          patterncolor_ := decimal cyanpart i & " " & decimal magentapart i & " " & decimal yellowpart i & " " & decimal blackpart i;
        fi
      endfor;)
    withprescript(" " & s & " THsetpattern")
    withprescript(" " & patterncolor_ & " THsetpatterncolor")
    withoutcolor
  else:
    p withcolor red;
    message("Warning: undefined pattern ignored");
  fi;
enddef;

def patterntransform expr t=
   Pmatrix_ := "[" & decimal xxpart t
              & " " & decimal yxpart t
              & " " & decimal xypart t
              & " " & decimal yypart t
              & " " & decimal xpart t
              & " " & decimal ypart t & "]";
enddef;

def patternxstep expr t=
   PXStep_ = t;
enddef;

def patternystep expr t=
   PYStep_ = t;
enddef;

def patternstep text t=
   if pair t:
      PXStep_ = xpart t;
      PYStep_ = ypart t;
   else:
      (PXStep_,PYStep_)=t;
   fi;
enddef;

def patterncolor expr t=
  message("Warning: patterncolor not supported in Therion");
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of pattern macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% transparent colors

primarydef p withalpha t =
    p withprescript(decimal t & " THsetalpha")
enddef;

def withlinearshading (expr p, n, ca, cb) =
    withprescript("L " &
                  decimal xpart point n of tightbbox p & " " &
                  decimal ypart point n of tightbbox p & " " &
                  decimal xpart point ((n+2) mod 4) of tightbbox  p & " " &
                  decimal ypart point ((n+2) mod 4) of tightbbox  p & " " &
                  colortostr(ca, " ") & " " &
                  colortostr(cb, " ") & " " &
                  "THgradient") withoutcolor
enddef;

def withradialshading (expr p, ca, cb) =
    withprescript("R " &
                  decimal xpart center p & " " &
                  decimal ypart center p & " " &
                  decimal xpart center p & " " &
                  decimal ypart center p & " " &
                  colortostr(ca, " ") & " " &
                  colortostr(cb, " ") & " " &
                  "0 " &
                  decimal (((xpart lrcorner p - xpart llcorner p) ++ (ypart urcorner p - ypart lrcorner p)) / 2) & " " &
                  "THgradient") withoutcolor
enddef;

% compatibility macros for old-style transparency definitions:

def def_transparent_rgb (suffix name)(expr r, g, b) =
  message("[Warning: obsolete transparent colour definition '" & str name & "']");
  scantokens("rgbcolor " & str name & "; " & str name & ":=(" & decimal r & "," & decimal g & "," & decimal b & ");");
enddef;

primarydef p withtransparentcolor s =
  hide(message("[Warning: obsolete 'withtransparentcolor' option; use 'withcolor <color> withalpha <number>' instead]"))
  p withcolor s withalpha 0.75
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some useful macros from H. Hagen's MetaFun package (adapted)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vardef paired (expr d) =
  if pair d : d else : (d,d) fi
enddef ;

primarydef p randomshifted s =
  begingroup ; save ss ; pair ss ; ss := paired(s) ;
  p shifted (-.5xpart ss + uniformdeviate xpart ss,
             -.5ypart ss + uniformdeviate ypart ss)
  endgroup
enddef ;

primarydef p randomized s =
  (if path p :
    for i=0 upto length(p)-1 :
      ((point       i    of p) randomshifted s) .. controls
      ((postcontrol i    of p) randomshifted s) and
      ((precontrol (i+1) of p) randomshifted s) ..
    endfor
    if cycle p :
      cycle
    else :
      ((point length(p) of p) randomshifted s)
    fi
  elseif pair p :
    p randomshifted s
  elseif color p :
    if color s :
      (uniformdeviate redpart   s * redpart   p,
       uniformdeviate greenpart s * greenpart p,
       uniformdeviate bluepart  s * bluepart  p)
    elseif pair s :
      ((xpart s + uniformdeviate (ypart s - xpart s)) * p)
    else :
      (uniformdeviate s * p)
    fi
  else :
    p + uniformdeviate s
  fi)
enddef ;

primarydef p llmoved d =
  ((llcorner p) shifted (-xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p lrmoved d =
  ((lrcorner p) shifted (+xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p urmoved d =
  ((urcorner p) shifted (+xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p ulmoved d =
  ((ulcorner p) shifted (-xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p smoothed d =
  (p llmoved (-xpart paired(d),0) -- p lrmoved (-xpart paired(d),0) {right} ..
   p lrmoved (0,-ypart paired(d)) -- p urmoved (0,-ypart paired(d)) {up}    ..
   p urmoved (-xpart paired(d),0) -- p ulmoved (-xpart paired(d),0) {left}  ..
   p ulmoved (0,-ypart paired(d)) -- p llmoved (0,-ypart paired(d)) {down}  .. cycle)
enddef ;

vardef punked primary p =
  (point 0 of p for i=1 upto length(p)-1 : -- point i of p endfor
   if cycle p : -- cycle else : -- point length(p) of p fi)
enddef ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of MetaFun macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% we input map symbol definitions




%%%%% INPUT thPoint %%%%%


%% therion source code
%%
%% This file defines macros for point map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPoint.mp,v $
%% $Revision: 1.8 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

pair U;

def p_stalactite_UIS(expr pos,theta,sc,al) =
    U:=(.15u, .4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
    thdraw (0,.15u) -- (.15u,.4u);
enddef;

def p_stalagmite_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
    thdraw (0,-.15u) -- (.15u,-.4u);
enddef;

def p_pillar_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.15u)--(0,-.15u);
    thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
enddef;

def p_curtain_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    thdraw (0,.15u)--(0,0){dir 180}..(-.12u,-.11u)..{dir 0}(0,-.22u)--(0,-.4u);
enddef;

def p_helictite_UIS(expr pos,theta,sc,al) =
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u)--(0,-.4u);
    p := (-.2u,.4u)---(-.2u,.1u){down}..{dir -10}(-.1u,0.02u)---origin;
    thdraw p;
    thdraw p reflectedabout (origin,(0,u)) reflectedabout (origin,(u,0));
enddef;

def p_sodastraw_UIS(expr pos,theta,sc,al) =
    U:=(.5u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    pickup PenD;
    thdraw (-.4u,.2u)--(-.4u,0);
    thdraw (-.12u,.2u)--(-.12u,-.25u);
    thdraw (.02u,.2u)--(.02u,-.1u);
    thdraw (.23u,.2u)--(.23u,-.19u);
    thdraw (.35u,.2u)--(.35u,-.15u);
enddef;

def p_crystal_UIS (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
enddef;

def p_flowstone_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.15*u,0)--(.15*u,0));
    thdraw p shifted (.3u,-.1u);
    thdraw p shifted (-.3u,-.1u);
    thdraw p shifted (0,.1u);
enddef;

def p_moonmilk_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u){up}..{dir -60}(-.18u,-.105u){dir 80}..
        {dir-80}(.18u,-.105u){dir 60}..{down}(.5u,-.2u);
enddef;

def p_wallcalcite_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.2u)--(0,.1u)--(.2u,-.2u);
enddef;

def p_popcorn_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u)--(.5u,-.2u);
    pickup PenD;
    thdraw (-.3u,-.2u)--(-.3u,.1u);
    thdraw (0,-.2u)--(0,.1u);
    thdraw (.3u,-.2u)--(.3u,.1u);
    thfill fullcircle scaled .2u shifted (-.3u,.1u);
    thfill fullcircle scaled .2u shifted (0,.1u);
    thfill fullcircle scaled .2u shifted (.3u,.1u);
enddef;

def p_disk_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.3u)--origin--(.2u,-.3u);
    p:=fullcircle scaled .3u shifted (0,.15u);
    thclean p;
    thdraw p;
enddef;

def p_gypsum_NSS (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.25u,0)--(.25u,0);
    thdraw (0,-.25u)--(0,.25u);
enddef;

def p_aragonite_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u)--(0,.3u);
    thdraw (0,-.1u){dir 40}..{dir 5}(.3u,.08u);
    thdraw (0,-.1u){dir 140}..{dir 175}(-.3u,.08u);
    thdraw (0,.2u){dir 30}..{dir 5}(.25u,.3u);
    thdraw (0,.2u){dir 150}..{dir 175}(-.25u,.3u);
enddef;


def p_cavepearl_SKBB (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=fullcircle scaled .25u shifted (0,.16u);
    thdraw p;
    thdraw p rotated 120;
    thdraw p rotated 240;
enddef;

def p_gypsumflower_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
%    thdraw (.2u,0){left}..(0,.2u)..(.25u,.35u)..(.5u,0)..
%        (.1u,-.3u)..{dir 125}(-.5u,.2u);
    thdraw (.18u,0){left}..(0,.15u)..(.2u,.3u)..(.4u,0)..
        (.15u,-.28u)..{dir 120}(-.4u,.15u);
enddef;

def p_rimstonepool_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
    thfill buildcycle(p,((.5u,.1u)--(-.5u,.1u)));
    thdraw p;
enddef;

def p_rimstonedam_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
enddef;

def p_anastomosis_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.3u){dir -85}..{dir 85}(-.32u,-.3u)..(-.28u,.3u){dir 85}..
        {dir -85}(-.12u,.3u)..(-.08u,-.3u){dir-85}..{dir 85}(.08u,-.3u)..
        {dir85}(.12u,.3u)..(.28u,.3u){dir -85}..(.32u,-.3u){dir -85}..
        {dir 85}(.5u,-.3u);
enddef;

def p_karren_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.2u)--(-.3u,-.3u)--(0,.3u)--(.1u,.2u);
    thdraw p;
    thdraw p shifted (.3u,0);
enddef;

def p_scallop_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u){dir 125}..{dir 105}(-.2u,.1u){up}..
        {down}(.2u,.1u){dir -105}...{dir -125}(0,-.4u);
enddef;

def p_flute_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    thdraw (-.3u,.2u){dir -70}..{dir 70}(.3u,.2u);
enddef;

def p_raft_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u){dir -80}..(-.3u,-.2u)..origin..(.3u,.2u)..
        {dir -80}(.5u,-.2u);
enddef;

def p_raftcone_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,.4u)--(.3u,-.4u);
enddef;

def p_spring_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.2u){down}..(0,-.2u)..{up}(.3u,.2u);
enddef;

def p_sink_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.2u){up}..(0,.2u)..{down}(.3u,-.2u);
enddef;

def p_narrowend_UIS (expr pos,theta,sc,al)=
    U:=(.1u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.4u)--(-.1u,.4u);
    thdraw (.1u,-.4u)--(.1u,.4u);
enddef;

def p_lowend_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,-.1u)--(.4u,-.1u);
    thdraw (-.4u,.1u)--(.4u,.1u);
enddef;

def p_lowend_NSS (expr pos,theta,sc,al)=
    U:=(.4u,0);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,0)--(.4u,0);
enddef;

def p_flowstonechoke_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.4u){right}..{dir120}(-.2u,-.2u){dir -20}..{up}(0,0);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p reflectedabout (origin,down);
    thdraw p reflectedabout (origin,down) shifted (0,.2u);
enddef;

def p_breakdownchoke_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.1u)--(-.15u,.05u)--(-.48u,.2u)--cycle;
    thdraw (-.2u,-.2u)--(.15u,-.18u)--(-.08u,.14u)--cycle;
    thdraw (.1u,0)--(.4u,-.1u)--(.5u,.2u)--(.1u,.2u)--cycle;
enddef;

def p_bedrock_ASF (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,0)--(.5u,0);
    thdraw (-.3u,0)--(-.3u,.2u);
    thdraw (.3u,0)--(.3u,-.2u);
enddef;

def p_sand_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenB;
    thdraw (0,.2u);
    thdraw (0,.2u) rotated 120;
    thdraw (0,.2u) rotated 240;
enddef;

def p_clay_SKBB (expr pos,theta,sc,al) =
    U:=(.3u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,0){up}..origin{down}..{up}(0.3u,0);
enddef;

def p_pebbles_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
    thdraw p rotated 20 shifted (0,.25u);
    thdraw p rotated -37 shifted (.25u,-.25u);
    thdraw p rotated -62 shifted (-.25u,-.25u);
enddef;

def p_debris_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,-.22u)--(-.4u,-.1u)--cycle;
    thdraw (.2u,-.4u)--(.4u,-.1u)--(.1u,-.1u)--cycle;
    thdraw (-.1u,0)--(.2u,.3u)--(-.2u,.3u)--cycle;
enddef;

def p_blocks_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.5u)--(.3u,-.4u)--(-.17u,.2u)--cycle;
    thdraw (.25u,-.25u)--(.5u,-.15u)--(.3u,.5u)--(-.1u,.5u)--cycle;
    thdraw (-.27u,0)--(-.1u,.3u)--(-.5u,.35u)--cycle;
    pickup PenD;
    thdraw (-.5u,-.5u)--(-.1u,-.2u)--(-.17u,.2u);
    thdraw (-.1u,-.2u)--(.3u,-.4u);
    thdraw (.25u,-.25u)--(.3u,0)--(.2u,.2u)--(-.1u,.5u);
    thdraw (.3u,.5u)--(.2u,.2u);
    thdraw (.5u,-.15u)--(.3u,0);
enddef;

def p_water_UIS (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withpattern pattern_water_UIS;
    thdraw p;
enddef;

def p_ice_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (0,.05u)--(0,.35u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
    p := (-0.15u,.2u)--(0.15u,.2u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
enddef;

def p_snow_SKBB (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := origin--(0,.25*u);
    q := ((0,.35u)--(0,0.25u)--(0.1u,0.25u)) rotatedaround ((0,0.25u),45);
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
    thdraw p rotated (180);
    thdraw p rotated (240);
    thdraw p rotated (300);
    thdraw q;
    thdraw q rotated (60);
    thdraw q rotated (120);
    thdraw q rotated (180);
    thdraw q rotated (240);
    thdraw q rotated (300);
enddef;


def p_archeomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := fullcircle scaled .8u;
    thdraw (-.5u,-.5u)--origin cutbefore p;
    thdraw (-.5u,.5u)--origin cutbefore p;
    thdraw origin--(.4u,0);
    thdraw p;
enddef;

def p_paleomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.4u,-.2u)..(-.2u,-.08u)---(-.1u,.05u)---(0,.2u)..(-.03u,.4u)..
        (.2u,.3u)..(.35u,.25u)..(.2u,.2u)---origin---(-.1u,-.17u)..
        (-.08u,-.25u){dir -120}..(-.3u,-.23u)
        ..cycle;
enddef;

def p_guano_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir 40}..{down}(0,-.35u){up}..{dir-40}(.4u,.2u);
enddef;

def p_vegetabledebris_ASF (expr pos,theta,sc,al)=
    U:=(.38u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.3u)--(0,.3u);
    thdraw (0,-.3u)--(.3u,.3u);
    thdraw (-.25u,.13u)--(.38u,.13u);
    thdraw (-.38u,-.13u)--(.25u,-.13u);
enddef;

def p_root_ASF (expr pos,theta,sc,al)=
    U:=(.1u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.5u)--(-.1u,.5u);
    p:=(-.1u,-.3u)--(.1u,-.5u);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p shifted (0,.4u);
enddef;

def p_entrance_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.2u,-.5u)--(0,.5u)--(.2u,-.5u)--cycle;
enddef;

def p_waterflow_paleo_UIS (expr pos,theta,sc,al)=
    U:=(.2u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    thdraw halfcircle scaled .4u shifted (0,-.4u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_UIS (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_BCRA (expr pos,theta,sc,al)=
    U:=(.25u,0.7u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.25u,-0.7u)--(0,.7u)--(.25u,-.7u)--cycle;
enddef;

% by Philip Schuchardt
def p_gradient_NSS (expr pos,theta,sc,al) =
  U:=(.7u, .6u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;

  thdraw (-.3u, -.5u) -- (-.7u, -.2u);
  thdraw (-.2u, -.4u) -- (-.4u, .3u);
  thdraw (0u, -.3u) -- (0u, .6u);
  thdraw (.3u, -.5u) -- (.7u, -.2u);
  thdraw (.2u, -.4u) -- (.4u, .3u);
enddef;

def p_waterflow_permanent_UIS (expr pos,theta,sc,al)=
    U:=(.15u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(0,.5u){down}..(.12u,.3u)..(-.15u,.15u)..(.13u,0)..
        (-.08u,-.2u)..{down}(0,-.5u);
    p:=p rotated 180;
    thdraw p;
    thdrawoptions();
    oldahlength:=ahlength; ahlength:=2.5pt*optical_zoom;
    thdraw arrowhead p;
    thfill arrowhead p;
    ahlength:=oldahlength;
enddef;

def p_waterflow_intermittent_UIS (expr pos,theta,sc,al)=
  thdrawoptions(dashed evenly scaled (.5 * optical_zoom));
  p_waterflow_permanent_UIS (pos,theta,sc,al);
  thdrawoptions();
enddef;

def p_airdraught_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
	p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
	thdraw p;
	thdraw p reflectedabout (origin,(0,u));
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_airdraught_winter_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
enddef;

def p_airdraught_summer_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
  thclean fullcircle scaled 0.3u shifted (0,0.05u);
  thdraw fullcircle scaled 0.2u shifted (0,0.05u);
enddef;


def p_station_fixed_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    pair z;
    z:=(0,.2u);
    thclean z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw origin;
enddef;

def p_station_painted_SKBB (expr pos)=
    T:=identity shifted pos;
    pickup PenC;
    thclean fullcircle scaled 0.25u;
    thdraw fullcircle scaled 0.25u;
enddef;

def p_station_natural_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled .3u;
    thdraw fullcircle scaled .3u;
    thdraw origin;
enddef;

def p_station_temporary_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    p:=(-.2u,0)--(.2u,0);
    thdraw p;
    thdraw p rotated 90;
    thclean fullcircle scaled .16u;
    pickup PenC;
    thdraw origin;
enddef;

let p_station_temporary_SKBB = p_station_painted_SKBB;

def p_steps_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.3u)--(-.3u,.1u)--(-.1u,.1u)--(-.1u,-.1u)--
           (.1u,-.1u)--(.1u,-.3u)--(.3u,-.3u);
enddef;

def p_fixedladder_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,-.4u)--(-.15u,.4u);
    thdraw (.15u,-.4u)--(.15u,.4u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.15u,.2u)--(.15u,.2u);
    thdraw (-.15u,-.2u)--(.15u,-.2u);
enddef;

def p_ropeladder_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (.1u,-.4u)..(.2u,-.2u)..(.1u,.2u)..(.2u,.4u);
    thdraw (-.2u,-.4u)..(-.1u,-.2u)..(-.2u,.2u)..(-.1u,.4u);
    thdraw (-.2u,.2u)--(.1u,.2u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.1u,-.2u)--(.2u,-.2u);
enddef;

def p_bridge_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.2u)--(-.2u,.1u)--(.2u,.1u)--(.3u,.2u);
    thdraw (-.3u,-.2u)--(-.2u,-.1u)--(.2u,-.1u)--(.3u,-.2u);
enddef;

def p_noequipment_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thfill (0,-.1u)--(-.05u,.3u)--(.05u,.3u)--cycle;
    thdraw (0,-.2u) withpen PenX;
enddef;

def p_anchor_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thdraw fullcircle scaled .2u shifted (0.2u,0) withpen PenC;
    begingroup;
      interim linecap:=butt;
      thdraw (-.3u,0)--(.1u,0) withpen PenA;
    endgroup;
    thdraw (.1u,-.4u)--(.1u,.4u) withpen PenD;
enddef;

def p_traverse_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.25u,.05u)..(0,-.08u)..(.25u,.05u);
    pickup pencircle scaled .18u;
    thdraw (-.25u,.05u);
    thdraw (.25u,.05u);
enddef;

def p_rope_SKBB (expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.2u,.2u)..origin..(.1u,.1u)--(.1u,-.4u);
    pickup pencircle scaled .18u;
    thdraw (-.2u,.2u);
    thdraw (.1u,.1u);
enddef;

def p_camp_SKBB (expr pos,r,s,al) =
    U:=(.4u, .5u);
    T:=identity aligned al scaled s shifted pos;
    pickup PenC;
    thdraw (-.4u,-.4u)--(0,.5u)--(.4u,-.4u)--cycle;
    pickup PenD;
    thdraw (0,-.4u)--(0,.5u);
enddef;


def p_dig_UIS (expr pos,r,s,al) =
    U:=(.4u, .5u);
    T:=identity aligned al scaled s shifted pos;
    thfill ((-.075u,-.5u){down} .. {up}(0.075u, -.5u) -- (0.075u, .15u) -- (0.3u, 0.15u) -- (0.3u, 0.5u) --
    (-.3u, .5u) -- (-.3u, .15u) -- (-.075u, .15u) -- cycle) rotated 45;
enddef;

def p_continuation_UIS(expr pos,theta,sc,al) =
  U:=(.15u,.3u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.1u,.2u){up}..{down}(.1u,.2u)..{down}(0,-.05u);
  pickup PenX;
  thdraw (0,-.2u);
enddef;

def p_station_SKBB(expr pos,mark,txt)(text flags) =
  T:=identity shifted pos;

  if mark=4: p_station_fixed(pos)
  elseif mark=3: p_station_natural(pos)
  elseif mark=2: p_station_painted(pos)
  elseif mark=1: p_station_temporary(pos)
  fi;

  path path_cave;
  path_cave = (-.3u,-.25u) -- (-.2u,-.25u){dir 135} .. (0, .25u) .. {dir 225}(.2u,-.25u) -- (.3u,-.25u);
  for i=flags:
    pickup PenX;
    if i="entrance":
%      thfill fullcircle scaled 1 cm withcolor blue withalpha 0.5;
      thdraw path_cave;
%      p_label.urt(txt,pos+(0.4u,0),0,0);
      if not numeric txt:
        p_smartlabel(txt,pos);
      fi;
    elseif i="sink":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.02u) -- (0,.05u) -- (.15u,-.02u) withcolor blue;
    elseif i="spring":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.38u) -- (0,-.45u) -- (.15u,-.38u) withcolor blue;
    elseif i="doline":
      thdraw (-.5u,.05u){down}..(0,-0.6u)..{up}(.5u,.05u);
    elseif i="dig":
      thdraw (-.5u,.25u) -- (-.35u,.25u)--(-.23u,-.25u)--(.23u,-.25u)--(.35u,.25u)--(.5u,.25u);
    elseif substring(0,11) of i = "air-draught":
      pickup PenB;
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u));
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (.11u,0);
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (-.11u,0);
    elseif i="continuation":
      if picture(txt):
        picture ATTR__text;
        ATTR__text := txt;
      fi;
      begingroup;
        save T; transform T;
        p_continuation(pos+(0,.25u),0,1,(0,1));
      endgroup;
      if picture(txt):
        save ATTR__text;
      fi;
    elseif i="arch":
      thdraw (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
      thfill (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
    elseif i="overhang":
      thdraw (.2u,-.25u)--(-.2u,-.25u){up}..{right}(.2u,.25u);
    fi;
  endfor;
%  thdraw (0,0) withpen PenX withcolor red;
enddef;

def p_debug (expr col, pen, pos)=
    T:=identity shifted pos;
    thdraw origin withpen pencircle
      scaled if pen=0: 2pt
                 else: 4pt fi
      withcolor if col=-2: (1,.85,0)
           elseif col=-1: black
           elseif col=0: red
           else: blue fi;
enddef;


def p_u(expr pos,theta,sc,al) =
  T:=identity shifted pos;
  thdraw origin withpen pencircle scaled 4pt withcolor red;
enddef;

def p_handrail_SKBB(expr pos,theta,sc,al) =
    tmph := 1 / Scale * 72 / 2.54;  % 1 m height
    U:=(.1u, tmph);
    pickup PenC;
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thdraw (0,0) -- (0,tmph);
    thdraw (0,tmph) withpen pencircle scaled .25u;
enddef;

def p_viaferrata_SKBB(expr pos,r,s,al) =
    U:=(.4u, .4u);
    T:=identity aligned al scaled s shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,.15u)--(-.15u,.1u)--(.15u,.1u)--(.15u,.15u);
    thdraw (-.15u,-.05u)--(-.15u,-.1u)--(.15u,-.1u)--(.15u,-.05u);
enddef;

def p_stalagmites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
        thdraw (0,-.15u) -- (.15u,-.4u);
    endfor;
enddef;

def p_stalactites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
        thdraw (0,.15u) -- (.15u,.4u);
    endfor;
enddef;

def p_gradient_SKBB (expr pos,theta,sc,al)=
    U:=(.3u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.6u)--(-.3u,.6u);
    thdraw (0,-.6u)--(0,-0.2u);
    thdraw (.3u,-.6u)--(.3u,.6u);
enddef;

def p_pillars_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.15u)--(0,-.15u);
        thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
        thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    endfor;
enddef;





%%%%% ENDINPUT thPoint %%%%%





%%%%% INPUT thLine %%%%%


%% therion source code
%%
%% This file defines macros for line symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thLine.mp,v $
%% $Revision: 1.4 $
%%
%% Copyright (C) 2000 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

% some definitions

% adjust step according to the length of the path; return at least two steps

vardef adjust_step (expr len, s) =
  if s <= len/2: len / (floor(len / s))
  else: len/2 fi
enddef;

def mark_(expr p,t,l) =
  thdraw (point t of p) --
          ((point t of p) + l * unitvector(thdir(p,t) rotated 90));
enddef;

vardef thdir (expr p,t) =    % 1 * epsilon caused problems in scales < 1:1000
                             % n * epsilon is enough for scale 1:(n*1000)
  if arclength(p)=0:
    hide(thwarning("unable to determine direction on zero-length path"))
    (0,1)
  else:
%  ((direction t-100*epsilon of p) + (direction t+100*epsilon of p)) / 2
   postcontrol (t+1000*epsilon) of p - precontrol (t-1000*epsilon) of p
%  direction t of p
  fi
enddef;

vardef polyline_offset(expr p, amount, direction) =
  % direction should be 90 or -90
  save P;
  path P,R;
  P = punked p;   % convert to polyline
  pair za, zb;
  for i=0 upto length P:
    if i > 0:
      za := unitvector(point i of P - point i-1 of P);      % direction of the previous segment
    else:                       % the first segment
      if cycle P:
        za := unitvector(point length P of P - point (length P)-1 of P);
      else:
        za := unitvector(point 1 of P - point 0 of P);    % za == zb
      fi;
    fi;
    if i < length P:
      zb := unitvector(point i+1 of P - point i of P);    % direction of the next segment
    else:                       % the last segment
      if cycle P:
        % zb is unused as the path is closed by "-- cycle"
      else:
        zb := za;
      fi;
    fi;
    A := 180-(angle(za)-angle(zb));
    R := if i>0: R -- fi
         if (i=length P) and cycle P: cycle else:
         point i of P + amount*unitvector(((za+zb)/2) rotated direction)/abs(sind(A/2)) fi;
  endfor;
  R
enddef;


% walls:

def l_wall_bedrock_UIS (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_sand_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenB;
  forever:
    t := arctime cas of P;
    thdraw ((point t of P) + (uniformdeviate 1) * .4u
            * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_pebbles_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .35u);
  pickup PenC;
  q:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/20) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_clay_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  q := (-0.15u,0){up}..{down}origin..{up}(0.15u,0);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_debris_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .4u);
  pickup PenC;
%  q := ((-.1u,-.15u)--(.2,.03u)--(-.2u,.15u)--cycle) scaled 1.5;
  q := ((-.2u,-.1u)--(.2u,-.1u)--(0,.2u)--cycle) scaled 1.1;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/10) rotated uniformdeviate (360) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_blocks_SKBB (expr P) =
%  pickup PenD;
%  draw P withcolor red;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
if dlzka > 0:
  mojkrok:=adjust_step(dlzka, 1.5u);
  pickup PenA;
  forever:
    t1 := arctime (cas + mojkrok*1/10) of P;
    t2 := arctime (cas + mojkrok*9/10) of P;
    q := ((point t1 of P) + .4u * unitvector(thdir(P,t1) rotated -90)) --
         (subpath (t1,t2) of P) --
         ((point t2 of P) + .4u * unitvector(thdir(P,t2) rotated -90));
    thdraw q randomized (u/6);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
fi;
enddef;

def l_wall_ice_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  p := (-.1u,0)--(.1u,0);
  q := (0,-.1u)--(0,.1u);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw p shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_underlying_UIS (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_wall_unsurveyed_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P;
enddef;

def l_wall_presumed_UIS (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled (2*optical_zoom);
enddef;

% other line symbols

def l_pit_UIS (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenD;
  forever:
    t := arctime cas of P;
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;
  thdraw P;
enddef;

let l_floorstep_UIS = l_pit_UIS;

def l_overhang_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.3u);
  pickup PenC;
  t1:=0;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok) of P;
    if cas + mojkrok >= dlzka: t2 := arctime (dlzka-epsilon) of P; fi
    thfill (subpath (t1,t2) of P) --
      ((point t of P) + .3u * unitvector(thdir(P,t) rotated 90)) --
      cycle;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
    t1:=t2;
  endfor;
  thdraw P;
enddef;


def l_chimney_UIS (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_ceilingstep_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_ceilingmeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


%Bruce Mutton 2012.06.16 uses general code for l_ceilingmeander_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on outside (rock) side of lines
def l_ceilingmeander_UIS (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;                           % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);  % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.2u * Pv) --
          (Pp + 0.3u * Pv);              % add 0.1u to each moves ticks outside
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);
    thdraw (Pp - 0.2u * Pv) --
          (Pp - 0.3u * Pv);              % subtract 0.1u to each moves ticks outside
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3);  % for rounding errors
  endfor;
enddef;

let l_ceilingmeander_NZSS = l_ceilingmeander_UIS;

%Bruce Mutton 2012.06.16 uses general code for l_ceilingstep_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on righthand (rock) side of line
def l_ceilingstep_UIS (expr P) =
  T:=identity;
  cas := 0;                            % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);   % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,-0.2u);                  % change sign to -0.2u
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

let l_ceilingstep_NZSS = l_ceilingstep_UIS;

%Bruce Mutton 2012.06.10 uses general code for l_pit_UIS defined in therion source code by Martin Budaj 5.3.9
% dots on righthand (rock) side of line spaced 0.2u, 0.2u same as floor-step ticks
def l_chimney_NZSS (expr P) =
	T:=identity;
	cas := 0;                            % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 0.25u);  % symbol length nudged to be multiple of path length
	q:= (0.20u,-0.20u) -- (0.21u,-0.21u);         % dot

	pickup PenC;  %2nd thinnest pen
	forever:
	  t := arctime cas of P;
	thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % draw dots
	cas := cas + mojkrok;
	  exitif cas > dlzka + (mojkrok / 3); % for rounding errors
	endfor;
	pickup PenB;   %2nd thickest pen
	thdraw P;      %continuous line
enddef;

%Bruce Mutton 2010.06.20 uses general code and adjust_step defined in therion source code by Martin Budaj
%for Therion 5.3.8
def l_wall_presumed_NZSS (expr P) =
	T:=identity;
	cas := 0;                                 % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 1.5u);        % symbol length nudged to be multiple of path length
	q  := (-0.2u,-0.4u)--(0,0)--(0.2u,-0.4u); % define v shape
	forever:
	  t1 := arctime (cas + mojkrok*1/5) of P;
	  t  := arctime (cas + mojkrok/2) of P;
	  t2 := arctime (cas + mojkrok*4/5) of P;
		pickup PenA;                          % thick
	thdraw (subpath (t1,t2) of P);          % dash
	  pickup PenC;                          % thin
	  thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % v shape

	  cas := cas + mojkrok;
	  exitif cas > dlzka - (2*mojkrok/3);     % for rounding errors
	endfor;
enddef;

def l_floormeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  pair PPp;
  pair PPd;
  pair PPv;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenC;
  forever:
    t := arctime cas of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    if cas > 0:
      thdraw (PPp + 0.2u * PPv) --
          (Pp + 0.2u * Pv);
      thdraw (PPp - 0.2u * PPv) --
          (Pp - 0.2u * Pv);
    fi;
    PPp := Pp;
    PPd := Pd;
    PPv := Pv;
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
enddef;

boolean alw_perpendicular;

def l_slope_SKBB (expr P,S)(text Q) =
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1;
    else:
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360;
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) /
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) /
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u:
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false;
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) /
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi;
      l:=lengths[t];
    fi;

    a := a + angle(thdir(P,t));

    thdraw (point t of P) --
      ((point t of P) + if par: 0.333 * fi l * unitvector(dir(a)));
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
  if S = 1: pickup PenC; draw P fi;
%pickup pencircle scaled 3pt;
%for i=0 upto li: draw point i of P; endfor;
enddef;


def l_slope_BCRA (expr P,S)(text Q) =
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1;
    else:
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360;
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) /
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) /
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u:
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false;
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) /
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi;
      l:=lengths[t];
    fi;

    a := a + angle(thdir(P,t));

    if par:
      thfill (point t of P) + mojkrok/2.5 * unitvector(dir(a+90))--
        ((point t of P) + l * unitvector(dir(a))) --
        (point t of P) + mojkrok/2.5 * unitvector(dir(a-90)) -- cycle;
    fi;
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
enddef;


def l_contour_UIS(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if pnt=-2:
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_contour_SKBB(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if (pnt=-2) or (pnt=-1):
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_rockborder_UIS (expr P) =
  T:=identity;
  pickup PenC;
  if cycle P: thclean P fi;
  thdraw P;
enddef;

def l_rockedge_UIS (expr P) =
  T:=identity;
  pickup PenD;
  thdraw P;
enddef;

def l_border_visible_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path;
enddef;

def l_border_temporary_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled optical_zoom;
enddef;

def l_flowstone_UIS (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .7u);
  if (cycle P) and (dlzka < 3.5u):   % make at least 5 curls on a cyclic path
    mojkrok := dlzka/5;
  fi;
  pickup PenC;
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 60)} ..
           {dir (angle(thdir(P,t2)) - 60)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_moonmilk_UIS (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .3u);
  pickup PenC;
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 80)} ..
           {dir (angle(thdir(P,t2)) - 80)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_survey_surface_SKBB (expr P) =
  T:=identity;
  thdrawoptions(dashed withdots scaled (0.2 * optical_zoom) withpen PenC);
  thdraw P;
  thdrawoptions();
enddef;

def l_survey_cave_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  if ATTR__scrap_centerline:
    thdraw P;
  else:
    PolygonLine:=.8u;
    pair zz[];
    for t = 0 upto length P - 1:
      zz1 := point t of P;
      zz2 := point t+1 of P;
      if length (zz2-zz1) > 2*PolygonLine:
        thdraw zz1 -- zz1 + PolygonLine * unitvector(zz2 - zz1);
        thdraw zz2 -- zz2 + PolygonLine * unitvector(zz1 - zz2);
      else:
        thdraw zz1 -- zz2;
      fi;
    endfor;
  fi;
enddef;

def l_survey_cave_UIS (expr P) =
  T:=identity;
  pair zz[];
  pickup PenC;
  for t = 0 upto length P - 1:
    zz1 := point t of P;
    zz2 := point t+1 of P;
    draw zz1 -- zz2;
  endfor;
enddef;

def l_waterflow_permanent_UIS (expr Path) =
  path ppp;
  T:=identity;
  cas := 0;
  dlzka := arclength Path;
  mojkrok:=adjust_step(dlzka, 0.5u);
    pickup PenD;
    vardef azim = 50 + 15*normaldeviate enddef;
    az1 := azim;
    sgn := 1;
    ppp := point 0 of Path;
    forever:
        t1 := arctime cas of Path;
        t2 := arctime (cas+mojkrok) of Path;
        if cas+1.1*mojkrok > dlzka:
            az2 := 0;
        else:
            az2 := azim;
        fi;
        d1 := angle(thdir(Path,t1)) + sgn * az1;
        d2 := angle(thdir(Path,t2)) - sgn * az2;
        ppp := ppp & (point t1 of Path){dir d1} .. {dir d2}(point t2 of Path);
        az1 := az2;
        sgn := -1 * sgn;
        cas := cas + mojkrok;
        exitif cas > dlzka + mojkrok/3;     % for rounding errors
    endfor;
%    drawarrow ppp;
    thdraw ppp;
    thdrawoptions();
    oldahlength:=ahlength;
    ahlength:=ahlength*optical_zoom;
    thdraw arrowhead ppp;
    thfill arrowhead ppp;
    ahlength:=oldahlength;
enddef;

def l_waterflow_intermittent_SKBB (expr Path) =
  thdrawoptions(dashed evenly scaled optical_zoom);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_waterflow_conjectural_SKBB (expr Path) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_invisible (expr P) =
enddef;

def l_undefined (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P withcolor red;
  thwarning("undefined line symbol used");
enddef;

% Q = 0 -- no arrows
%     1 -- end
%     2 -- begin
%     3 -- both

def l_arrow_SKBB (expr P, Q) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p := (-.1u,-.25u)--(0,0)--(.1u,-.25u);
  if odd Q:
    draw p rotated (angle(thdir(P,0))+90) shifted (point 0 of P);
  fi;
  if Q>1:
    draw p rotated (angle(thdir(P,length P))-90)
         shifted (point infinity of P);
  fi;
enddef;

def l_mapconnection_SKBB (expr P) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_arrow_SKBB(P,3);
  thdrawoptions();
enddef;


def l_section_SKBB (expr P)(text txt) =
  T:=identity;
  path Q; Q = punked P;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := postcontrol t of P;
    zz4 := precontrol t+1 of P;
    if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or
       (length(zz4-2/3[zz1,zz2]) > 0.1pt):
      zz5 = whatever[zz1,zz2];
      (zz3-zz5) = whatever * (zz1-zz2) rotated 90;
      draw zz1--zz5;
      zz6 = whatever[zz1,zz2];
      (zz4-zz6) = whatever * (zz1-zz2) rotated 90;
      draw zz2--zz6;
    else:
      draw zz1--zz2;
    fi;
  endfor;
  for pnt=txt:
    if pnt=-1:
    else:
      T:=identity rotated angle(thdir(Q,pnt)) shifted (point pnt of Q);
      pickup PenC;
      thdraw (0,0)--(0,.8u);
      thdraw (-.1u,.55u)--(0,.8u)--(.1u,.55u);
    fi;
    exitif pnt=-1;
  endfor;
enddef;

let l_border_invisible = l_invisible;
let l_wall_invisible = l_invisible;

def l_debug (expr col, pen, P) =
  T:=identity;
  pickup if pen=0: PenD else: PenB fi;
  thdraw P
    withcolor if col=-2: (1,.85,0)
          elseif col=-1: black
           elseif col=0: red
                   else: blue fi;
enddef;


def l_u (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P withcolor red;
enddef;


def l_gradient_UIS (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p:=(-.15u,-.4u)--(0,0)--(.15u,-.4u)--cycle;
  thfill (p rotated (angle(thdir(P,length P))-90)
         shifted (point infinity of P));
  thdraw (p rotated (angle(thdir(P,length P))-90)
         shifted (point infinity of P));
enddef;

def l_gradient_BCRA (expr P) =
  T:=identity;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := unitvector(zz2 - zz1);
    thfill zz1 + u/3 * zz3 + .25u * (zz3 rotated 90) --
           zz2 - u/3 * zz3 --
	   zz1 + u/3 * zz3 + .25u * (zz3 rotated -90) -- cycle;
  endfor;
enddef;


def l_rope_SKBB (expr P, show_anchors, show_rebelays) =
  T:=identity;
  pickup PenC;
  if not show_rebelays:
    draw P;
  else:
    d:=0.5u;
    for i:=0 upto (length P - 2):
      x1 := xpart point i of P;
      y1 := ypart point i of P;
      x2 := xpart point i+1 of P;
      y2 := ypart point i+1 of P;

      if x1 = x2:
        if y2 > y1:
          draw (x1,y1-d) -- (x2,y2);
        else:
          draw (x1,y1) -- (x2,y2-d);
        fi;
      else:
        dx1:=x1; dy1:=y1; x1:=0; y1:=0; x2:=x2-dx1; y2:=y2-dy1;
        if y2 > y1:
          y3 := y1 - d;
          x3 := x1 + (x2-x1)*sqrt(d)/(sqrt(d)+sqrt(y2-y1+d));
        else:
          y3 := y2 - d;
          x3 := x1 + (x2-x1)*sqrt(y1-y2+d)/(sqrt(d)+sqrt(y1-y2+d));
        fi;
        numeric a,b,c;
        a*x1/10*x1 + b/10*x1 + c/10 = y1/10;
        a*x2/10*x2 + b/10*x2 + c/10 = y2/10;
        a*x3/10*x3 + b/10*x3 + c/10 = y3/10;
        draw (x1+dx1,y1+dy1)
        for t = x1 step (x2-x1)/20 until x2+10*epsilon:
          -- (t+dx1,a*t*t+b*t+c+dy1)
        endfor;
      fi;
    endfor;
    pair x;
    x = point (length P)-1 of P + whatever * down;
    x = point (length P) of P + whatever * right;
    draw point (length P)-1 of P -- x;
  fi;
  if show_anchors:
    for i:=0 upto length P if show_rebelays: -1 fi:
      thdraw point i of P withpen pencircle scaled 0.25u;
    endfor;
  fi;
enddef;

def l_border_presumed_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled (0.25 * optical_zoom);
enddef;

def l_steps_SKBB (expr P) =
 if known ATTR_c: c := scantokens ATTR_c; else: c := 2; fi;
 if ATTR__elevation:
   if (c < 2):
     thwarning("Invalid stairs definition (c<2)");
     pickup PenA;
     draw P withcolor red;
   else:
     path PP;
     if (ypart point 0 of P) < (ypart point length P of P):
       PP := P;
     else:
       PP := reverse P;
     fi;
     path p;
     for j:=0 upto ((length PP) - 1):
       p := (point j of PP) -- (point (j + 1) of PP);
       c := ceiling(abs((ypart point 0 of p) - (ypart point length p of p)) / (0.2 / Scale * 72 / 2.54));  % 20 cm height
       if (c < 2): c:=2 fi;
       pair cp;
       cp = point length p of p - point 0 of p;
       dx := (xpart cp) / c;
       dy := (ypart cp) / c;
       cp := point 0 of p;
       for i:= 0 upto c - 1:
         l_border_visible(cp -- cp + (0,dy) -- cp + (dx,dy));
         cp := cp + (dx, dy);
       endfor;
       %draw P;
     endfor;
   fi;
 else:
   if known ATTR_l: l := scantokens ATTR_l; else: l := (length(P)-2)/2; fi;
   if ((length(P) < 4) or (c < 2)) or ((odd length P) and (not known ATTR_l)):
     thwarning("Invalid stairs definition" if c<2: &" (c<2)" fi);
     pickup PenA;
     draw P withcolor red;
   else:
     path p, q;
     p = subpath (1, 1+l) of P;
     q = reverse subpath (l+2, length(P)) of P;
     lp := arclength(p);
     lq := arclength(q);
     for i=1 upto c:
       l_border_visible(point(arctime ((i-1)/(c-1)*lp) of p) of p -- point(arctime ((i-1)/(c-1)*lq) of q) of q);
     endfor;
     l_border_visible(p);
     l_border_visible(q);
     drawoptions(withcolor 0.3[black,white]);
     %p_label(decimal c, point 0.5 of P, 0, 6);
     drawoptions();
   fi;
 fi;
enddef;

def l_handrail_SKBB (expr P) =
    if ATTR__elevation:
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, 1u);
      pickup PenD;
      pair tmppoint;
      tmph := 1 / Scale * 72 / 2.54;  % 1 m height
      tmppoint:=(point 0 of P) +(0,tmph);
      forever:
        t := arctime cas of P;
        draw point t of P -- (point t of P)+(0,tmph) withpen PenD;
        if cas > 0:
          draw tmppoint -- (point t of P)+(0,tmph) withpen PenC;
          tmppoint := (point t of P)+(0,tmph);
        fi;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
    else:
      T:=identity;
      cas := 0;
      pair coord;
      sq_size:=0.12u;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, u);
      pickup PenD;
      forever:
        t := arctime cas of P;
        coord := point t of P;
        thfill coord+(-sq_size,-sq_size)--coord+(sq_size,-sq_size)--coord+(sq_size,sq_size)--coord+(-sq_size,sq_size)--cycle;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
      pickup PenC;
      thdraw P;
    fi;
enddef;

def l_fixedladder_SKBB (expr Q) =
  % TODO: support side view in elevation (front view could be the same as in the plan view)
  T:=identity;
  path P, P_left, P_right;
  P := punked Q;     % ensure that there is no bezier curve
  pair p_tmp, za, zb;
  len := arclength P;
  dt:=adjust_step(len, 0.3u);
  t := dt/2;
  wdth := 0.25u;     % half-width of the ladder
  pickup PenC;
  % draw the steps
  forever:
    p_tmp := point arctime t of P of P;
    draw p_tmp+wdth*unitvector(thdir(P,arctime t of P) rotated -90) --
         p_tmp+wdth*unitvector(thdir(P,arctime t of P) rotated  90);
    t := t + dt;
    exitif t > len + 10*epsilon;
  endfor;
  draw polyline_offset(P,wdth, 90);
  draw polyline_offset(P,wdth,-90);
enddef;

def l_ropeladder_SKBB (expr P) =
  pickup PenD;
  draw P withcolor red;
enddef;

def l_viaferrata_SKBB (expr P) =
  pickup PenD;
  draw P withcolor red;
enddef;




%%%%% ENDINPUT thLine %%%%%





%%%%% INPUT thArea %%%%%


%% therion source code
%%
%% This file defines tiling patterns
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPatterns.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

if unknown a_water_UIS: else: endinput fi;

% patterns

beginpattern(pattern_water_UIS);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sump_UIS);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sand_UIS);
    pickup PenC;
    draw (0.2u,.3u);
    draw (0.35u,.7u);
    draw (0.6u,.5u);
    draw (0.8u,.1u);
endpattern;

beginpattern(pattern_debris_SKBB);
    pickup PenC;
    p:=(-.15u,0)--(.15u,0);
    draw p rotated -40 shifted (.2u,.3u);
    draw p rotated 70 shifted (.9u,1.5u);
    draw p rotated 20 shifted (1.5u,.8u);
%    draw p rotated 95 shifted (.9u,.8u);
endpattern;


beginpattern(pattern_moonmilk_SKBB);
    pickup PenC;
    p:=(-.5u,0){down} .. {up}(-.1666u,0){down}..
        {up}(.1666u,0){down} .. {up}(.5u,0);
    draw p;
    draw p shifted (0.5u,0.3u);
    patternxstep(1.0u);
    patternystep(0.6u);
endpattern;


beginpattern(pattern_flowstone_ASF);
    pickup PenC;
    p:=(-.35u,0){dir -60} .. {dir 60}(0.35u,0);
    draw p;
    draw p shifted (0.35u,0.4u);
    patternxstep(u);
    patternystep(0.8u);
endpattern;


beginpattern(pattern_empty);
  patternbbox(0,0,10,10);
  patternstep(10,10);
endpattern;

% symbols

def a_water_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_water_UIS;
enddef;

def a_sump_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_sump_UIS;
enddef;


def a_flowstone_ASF (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_flowstone_ASF;
enddef;


def a_moonmilk_SKBB (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_moonmilk_SKBB;
enddef;



def a_sand_UIS (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic;
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw origin shifted ((i,j) randomized 0.7u) withpen PenC;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_debris_UIS (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_debris_SKBB;
enddef;


def a_bedrock_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


% used to export centerline LRUD envelope for maps created from surveys

def a_dimensions_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


def a_debris_SKBB (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic;
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw ((-.2u,0)--(.2u,0))
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 0.6u) withpen PenC;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_clay_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic;
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := ((-.25u,0){up}..origin{down}..{up}(0.25u,0)) randomized (u/15)
             shifted ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_ice_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic, tmp_ice;
  pair z;
  tmp_ice := image (
    draw (-.2u,0)--(.2u,0);
    draw (0,-.2u)--(0,.2u);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z := ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes ((bbox tmp_ice) shifted z)) < 0:
	  draw tmp_ice shifted z;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_snow_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn;
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z:=((i,j) randomized 1.3u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to P;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic;
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart llcorner q)/100);
  tmp_pic := image(
    for i = xpart llcorner q step 2uu until xpart urcorner q:
      for j = ypart llcorner q step 2uu until ypart urcorner q:
        qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle)
	     randomized (uu/2))
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 1.6uu);
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB_ (expr p,o,s_beg,s_end,d_beg,d_end) =
  T:=identity;
  orient = 90-o;
  pickup PenC;
  path q[], qq; q1 = bbox p;
  draw q1; draw p;
  q2 = llcorner q1 .. lrcorner q1 .. urcorner q1 .. ulcorner q1 .. cycle;
  draw q2;
  pair zz[];
  radius := .5*length(llcorner q1 - urcorner q1);
  zz1 := .5[llcorner q1,urcorner q1];
  zz2 := zz1 - dir(orient)*radius;
  zz3 = zz1 rotatedaround (zz2,90);
  draw zz1 withpen pencircle scaled 2mm;
  draw zz2 withpen pencircle scaled 2mm;
  draw zz3 withpen pencircle scaled 2mm;
  picture tmp_pic;
  tmp_pic := image(
    j := 0;
    forever:
      i := 0;
      forever:
        qq := punked (((-.5,-.5)--(.5,-.5)--(.5,.5)--(-.5,.5)--cycle)
             scaled (0.7(5u-(j/(2*radius))[u*s_beg,u*s_end]))
	     randomized (u/2))
             rotated uniformdeviate(360)
             shifted (((zz3 + (i,j)) rotatedaround (zz3,-o)) randomized 1.6u);
        draw ((zz3 + (i,j)) rotatedaround (zz3,-o)) withpen pencircle scaled 1mm withcolor red;
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
        i := i + (j/(2*radius))[u*d_beg,u*d_end];
        exitif i > 2*radius;
      endfor;
      j := j + (j/(2*radius))[u*d_beg,u*d_end];
      exitif j > 2*radius;
    endfor;
  );
%  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_pebbles_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic;
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := (superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75))
%             randomized (u/25)
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 0.8u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_water_SKBB (expr Path) =
  T:=identity;
  thfill Path;
enddef;

let a_sump_SKBB = a_water_SKBB;

def a_u (expr p) =
    T:=identity;
    thfill p withcolor red;
enddef;




%%%%% ENDINPUT thArea %%%%%





%%%%% INPUT thText %%%%%


%% therion source code
%%
%% This file defines macros for labels
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thText.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

labeloffset:=0bp;

def l_label(expr txt,path) =
  picture pict,pic;
  pair pos;
  numeric dx[],dy[],ptime;
  string ss,ch;

  pic := thelabel(txt,(0,0));
  strl := xpart(lrcorner pic - llcorner pic);
  pathl := arclength (path);
  dx0 := xpart(llcorner pic);
%  dy0 := ypart(llcorner pic);

  if strl>pathl:
    txtzoom := pathl / strl;
    thwarning("text scaled down to fit the path");
  else:
    txtzoom := 1;
  fi;
  zoom := pathl / strl;

  for p within pic:
    if textual p:
      ss := textpart p;
      dx1 := xpart p;
      dy1 := ypart p;
      dx2 := dx1;

      if xxpart p / yypart p <> 1: message("Error: distorted text!") fi;
      txtscale := txtzoom * xxpart p;

      l := length(ss);
      ptime := 0;
      for i=0 upto (l - 1):
        ch := substring(i,i+1) of ss;
        pict := ch infont fontpart p scaled txtscale;
        charwidth := xpart (lrcorner pict - llcorner pict) / txtzoom;
        dy2 := ypart lrcorner pict / txtzoom;
        ptime := (dx2 - dx0 + 0.5*charwidth) * zoom;
        t := arctime ptime of (path);
        pos := point t of path +
          (dy1+dy2)*txtzoom*unitvector((direction t of path) rotated 90);
        begingroup
%          interim labeloffset:=0bp;
          lab:=thelabel.top(pict,pos);
          process_label(pos,angle direction t of path);
        endgroup;
        dx2 := dx2 + charwidth;
      endfor;

    else: message("Strange component of line label!");
    fi;
  endfor;
  % draw path;
enddef;


% Label processing modes
% 0 = generic label
% 1 = altitude with a dot and increased offset from the anchor point
% 2 = semi circle up
% 3 = semi circle down
% 4 = semi circle up + semi circle down
% 5 = circle
% 6 = boxed label
% 7 = generic label for station name with an increased offset from the anchor point
% 8 = filled label; not implemented in the standard symbol sets, but see samples/q-marks for a usage example
p_label_mode_label:=0;
p_label_mode_station:=7;
p_label_mode_altitude:=1;
p_label_mode_date:=0;
p_label_mode_passageheight:=5;
p_label_mode_passageheightpos:=2;
p_label_mode_passageheightneg:=3;
p_label_mode_passageheightposneg:=4;
p_label_mode_height:=7;
p_label_mode_debugscrap:=6;
p_label_mode_debugstation:=7;

vardef p_label@#(expr txt,pos,rot,mode) =
  if (mode=1) or (mode=7): interim labeloffset:=(u/8) fi;
  lab:=thelabel@#(txt, pos);
  if mode>1: pickup PenD fi;
  if mode=1:
    pickup pencircle scaled (u/6);
    drawdot(pos);
    process_label(pos,0);
  elseif mode=2: process_uplabel;
  elseif mode=3: process_downlabel;
  elseif mode=4: process_updownlabel;
  elseif mode=5: process_circledlabel;
  elseif mode=6: process_boxedlabel;
  elseif mode=7: process_label(pos,rot);  % station name
  elseif mode=8: process_filledlabel(pos, rot);
  else: process_label(pos,rot); fi;
enddef;


% at beginfig: save smartll[], smartur[]; pair smartll[], smartur[]; smart_count=0;
numeric smart_count, smart_D;
boolean smart_quit, smart_inner_quit;

def p_smartlabel (expr txt, pos) =
 % -numbersystem=double gets bbox wrong for labels generated from empty strings; unnecessary to do anything in this case, anyway
 boolean exitdef; exitdef = false;
 if string txt: if txt = "": exitdef := true; fi; fi;
 if not exitdef:
  begingroup;
  interim bboxmargin:=0.2pt;
  lab:=thelabel.rt(txt,pos+(0.4u,0));
  q:=bbox lab;
  smart_D := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_D)),
                       ((point 2 of q) shifted (0,smart_D)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_D := smart_D - 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  smart_U := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_U)),
                       ((point 2 of q) shifted (0,smart_U)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_U := smart_U + 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  if (smart_U < -smart_D): smart_D := smart_U; fi;
  draw lab shifted (0,smart_D);
  if (abs(smart_D)>3pt):
    pickup PenB;
    draw pos{left}..{right}(pos shifted (.4u, smart_D)) dashed withdots scaled 0.2;
    pickup PenA;
    drawdot pos;
  fi;
  smart_count := smart_count + 1;
  smartll[smart_count] := point 0 of (q shifted (0,smart_D));
  smartur[smart_count] := point 2 of (q shifted (0,smart_D));
  endgroup;
 fi;
enddef;

def smart_overlap (expr llA, urA, llB, urB) =
  if ((xpart llA < xpart urB) and (xpart urA > xpart llB)) and
     ((ypart llA < ypart urB) and (ypart urA > ypart llB)):
    1
  else:
    0
  fi
enddef;




def p_wallaltitude (expr pprev,pos,pnext,txt) =
  rot:=angle(unitvector(pnext-pos)+unitvector(pos-pprev)) - 90;
  pickup PenD;
  pair zz;
%  zz:=(pos + 3*unitvector(dir rot));
  zz:=(pos + (u/4)*unitvector(dir rot));
  draw (pos)--zz;
  begingroup
%    interim labeloffset:=2pt;
    interim labeloffset:=(u/12);
    if horiz_labels:
      rot:=rot mod 360;
      if rot<=22.5: lab:=thelabel.rt(txt, zz);
      elseif rot<=67.5: lab:=thelabel.urt(txt, zz);
      elseif rot<=112.5: lab:=thelabel.top(txt, zz);
      elseif rot<=157.5: lab:=thelabel.ulft(txt, zz);
      elseif rot<=202.5: lab:=thelabel.lft(txt, zz);
      elseif rot<=247.5: lab:=thelabel.llft(txt, zz);
      elseif rot<=292.5: lab:=thelabel.bot(txt, zz);
      elseif rot<=337.5: lab:=thelabel.lrt(txt, zz);
      else: lab:=thelabel.rt(txt, zz);
      fi;
    else:
      if (abs rot>90) and (abs rot <=270):
        rot:=rot-180;
        lab:=thelabel.lft(txt, pos);
      else:
        lab:=thelabel.rt(txt, pos);
      fi;
    fi;
    process_label(pos, if horiz_labels: 0 else: rot fi);
  endgroup;
enddef;




%%%%% ENDINPUT thText %%%%%





%%%%% INPUT thSpecial %%%%%


%% therion source code
%%
%% This file defines macros for special symbols
%%
%% $Date: $
%% $RCSfile: $
%% $Revision: $
%%
%% Copyright (C) 2004 Martin Budaj
%%
%% --------------------------------------------------------------------
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

def s_northarrow_SKBB_old (expr rot) =
  T:=identity;
  picture tmp_pic;
  tmp_pic = image (
    begingroup
      interim defaultscale:=3;
      label(if (lang="sk") or (lang="cs"): "S" else: "N" fi, origin);
    endgroup;
    drawarrow (0,-1cm)--(0,1cm);
  );
  draw tmp_pic rotatedaround(origin, -rot);
enddef;

def s_northarrow_SKBB (expr rot) =
  T:=identity scaled 0.7 rotated -rot;
  thdraw (-.5cm,-1cm)--(0,1.5cm)--(.5cm,-1cm)--(0,-.5cm)--cycle;
  thfill (-.5cm,-1cm)--(0,1.5cm)--(0,-.5cm)--cycle;
enddef;

def s_scalebar_SKBB (expr l, units, txt) =
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  begingroup
    interim labeloffset:=2bp;
    label.top(thTEX(decimal (l) & "\thinspace" & txt),origin);
  endgroup
enddef;

def s_scalebar_SM (expr l, units, txt) =
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  draw (0,0)--(0,2bp);
  begingroup
    interim labeloffset:=3.5bp;
    label.top(thTEX(decimal (0)),(-tmpl,0));
    label.top(thTEX(decimal (l/2)),origin);
    label.top(thTEX(decimal (l) & "\thinspace" & txt),(tmpl,0));
  endgroup
enddef;


def s_hgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -5mm fi, 0
  ) -- (
    if xpos > 0: 0 else: 5mm fi, 0
  );
  draw (
    0, if ypos < 0: 0 else: -5mm fi
  ) -- (
    0, if ypos > 0: 0 else: 5mm fi
  );
enddef;


def s_vgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -xsize/2 fi, 0
  ) -- (
    if xpos > 0: 0 else: xsize/2 fi, 0
  ) dashed evenly;
enddef;

def s_vgrid_SKBB (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  mystep := adjust_step(xsize/2, 5mm);
  draw (
    if xpos < 0: 0 else: -xsize/2 fi, 0
  ) -- (
    if xpos > 0: 0 else: xsize/2 fi, 0
  ) dashed dashpattern (on mystep/4 off mystep/2 on mystep/4);
enddef;

def s_altitudebar_SKBB (expr zmin, zmax, units)(text t)(text labels) =
  begingroup;
    ncol := 0;  % number of colors
    for i=t:
      ncol := ncol+1;
    endfor;
    ncol := ncol / 2;  % t contains pairs
    j := 0;
    string s;
    hs := 36 bp;
    vs := ncol*25*bp + (ncol-1)*pt - 1bp;   % simulate the height of the discrete legend
    prevpos := -1;
    for i = t:
      if not odd j:
        k := (1-i)*vs;
      else:
        if prevpos >= 0:
          p := (0,prevpos)--(hs,prevpos)--(hs,k)--(0,k)--cycle;
          fill p withalpha -2 withlinearshading(p, 2.5, tmpcol, i);
        fi;
        tmpcol := i;
        prevpos := k;
      fi;
      j := j+1;
    endfor;
    % check if the labels parameter contains anything useful
    ii := 0;
    for i=labels:
      ii := ii+1;
    endfor;
    interim labeloffset := 15 bp;
    interim linecap := butt;
    if ii>1: % custom labeling
      j := 0;
      for i=labels:
        if not odd j:
          k := (1-i)*vs;
        else:
          draw (hs, k) -- (hs+5bp, k) withpen PenD;
          label.rt(thTEX(fixminus(i)), (hs, k));
        fi;
        j := j+1;
      endfor;
    else:   % calculated labeling; breakpoints for the (zmax-zmin) difference: 1*10^n, 2*10^n, 5*10^n
      d := zmax - zmin;
      dlog := log(d);
      if dlog mod 1 < 0.301: dv := 2;
      elseif dlog mod 1 < 0.7: dv := 5;
      else: dv := 10;
      fi;
      dv := floor(dv*(10**(floor(dlog-1))));
      if (dv > 0) or (floor zmax - floor zmin >= 2):
        if dv > 0:    % zmax-zmin >= 10
          i := dv * floor(zmin/dv);
          if i < zmin: i := i + dv; fi;
        else:         % at least two whole numbers between zmin and zmax
          i := floor(zmin);
          if i < zmin: i := i + 1; fi;
          dv := 1;
        fi;
        forever:
          exitif i > zmax;
          j := (i-zmin)/d*vs;
          draw (hs, j) -- (hs+5bp, j) withpen PenD;
          label.rt(thTEX(fixminus(decimal round i) & "\thinspace " & units), (hs, j));
          i := i + dv;
        endfor;
      else:
        draw (0, 0) -- (hs+5bp, 0) withpen PenD;
        draw (0, vs) -- (hs+5bp, vs) withpen PenD;
        label.rt(thTEX(fixminus(decimal(round(10*zmin)/10)) & "\thinspace " & units),(hs,0));
        label.rt(thTEX(fixminus(decimal(round(10*zmax)/10)) & "\thinspace " & units),(hs,vs));
      fi;
    fi;
  endgroup;
enddef;



%%%%% ENDINPUT thSpecial %%%%%





%%%%% INPUT uAUT %%%%%


% Austrian Symbol Set, author Georg Pacher
% enhanced 2017 by Benedikt Hallinger

% color (for Austrian symbol-set)

color col_water_bg;
col_water_bg :=(226/255,244/255,253/255);

%%%%%%%%%%%%%%%%%%%%%%%


%% areas

% returns true if pair point lies within path q.
% outside_point is any pair outside of path q (needed for reference).
vardef pointinside(expr pt,q,outside_point)=
  T:=identity;
  path test;
  test:= outside_point--pt;
  %thdraw test;
  boolean isinside;
  isinside:=false;
  numintersections:=recgetnumintersections(test,q,0);
  if (numintersections <0):
    isinside:=true;
  elseif odd(numintersections):
     isinside:=true;
  else:
     isinside:=false;
  fi;
  isinside
enddef;

% get number of intersection between paths p (length 1!) and q
% recnum is needed for limitation of recursions.
% If the number of allowed recursions is reached, a negative number of intersections is returned
vardef recgetnumintersections(expr p,q,recnum)=

  pair inter;
  save preinter;
  save postinter;
  save numintersections;
  path preinter, postinter;
  inter:=p intersectiontimes q;
  %show recnum;
  if recnum >25:
    numintersections:=-100;
  else:
    if xpart(inter)>0 :
     %show (xpart inter);
    % split p into two paths and call yourself again

    preinter:=subpath (0,xpart(inter)-2eps) of p;

    postinter:=subpath (xpart(inter)+2eps,1) of p;

    numintersections:= recgetnumintersections(preinter,q,recnum+1)
                     + recgetnumintersections(postinter,q,recnum+1)
                     + 1;
    else:
      numintersections:=0;
    fi;
  fi;
  numintersections

enddef;

beginpattern(pattern_water_AUT);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 90);
endpattern;

beginpattern(pattern_sump_AUT);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
endpattern;

beginpattern(pattern_sand_AUT);
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=0.0u step 0.2u until 2.4u:
        for j=0.0u step 0.2u until 2.4u:
          draw p rotated uniformdeviate(360)
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    if BaseScale<=2.5:
      my_step:=2.4u;
    else:
      my_step:=2.6u;
    fi;
    patternstep(my_step,my_step);
endpattern;

beginpattern(pattern_pebbles_AUT);
    pickup PenC;
    path qq;
    for i=0.0u step 0.3u until 5.1u:
        for j=0.0u step 0.3u until 5.1u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 0.15u);
           draw qq;
        endfor;
    endfor;
    patternstep(5.1u,5.1u);
endpattern;

beginpattern(pattern_ice_AUT);
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    draw p;
    draw p shifted (0.25u,.0u) rotated (90);
    draw p shifted (0.45u,0.25u);
    draw p shifted (0.0u,0.45u) rotated (90);
    patternxstep(.9u);
    patternystep(0.5u);
endpattern;

beginpattern(pattern_flowstone_AUT);
    pickup PenC;
    draw (0.0u, 0.01u)--(0.33u, 0.01u);
    draw (0.33u, 0.33u)--(0.66u, 0.33u);
    patternbbox(0u,0u, 0.66u, 0.66u); % definiert Rechteckgroesse des Symbols
endpattern;

def a_water_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_water_AUT;
  thdraw Path;
enddef;

def a_sump_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_sump_AUT;
  thdraw Path;
enddef;

def a_sand_AUT (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_sand_AUT ;
enddef;

def a_clay_AUT (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_sand_AUT;
enddef;


def a_pebbles_AUT (expr p) =
  T:=identity;
  thfill p withpattern pattern_pebbles_AUT;
enddef;



def a_debris_AUT (expr p) =
  T:=identity;

  symbol_distance:=1.0;
  scale_factor:= 0.3;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic;
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle)
           randomized (uu/2))
           scaled (uniformdeviate(0.4)+scale_factor )
           rotated uniformdeviate(360)
           shifted ((i,j) randomized 0.5uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 )
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_ice_AUT (expr p) =
  T:=identity;
  thclean p;
  thfill p withpattern pattern_ice_AUT;
  pickup PenC;
  thdraw p;
enddef;

def a_snow_AUT (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn;
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.0u until xpart urcorner q:
      for j = ypart llcorner q step 1.0u until ypart urcorner q:
        z:=((i,j) randomized 0.5u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;
    endfor;
  );
  clip tmp_pic to P;
  draw tmp_pic;
  thdraw P;
enddef;

def a_blocks_AUT (expr p) =
   T:=identity;
  symbol_distance:=1.6;
  scale_factor:= 0.8;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic;
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle)
           randomized (uu/2))
           scaled (uniformdeviate(0.7)+scale_factor )
           rotated uniformdeviate(360)
           shifted ((i,j) randomized 0.75uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 );
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_flowstone_AUT (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_flowstone_AUT ;
enddef;



%% lines

def l_wall_pit_AUT (expr P) =
    T:=identity;
    % draw outer path
    pickup PenA;
    thdraw P;

    laenge:= arclength P;

    pair inner[],innerdir[], inter;
    pair test;

    samplingdistance:=max(0.15u,laenge/1500);

    path testcircle;
    % testcircle, used to test, whether the path makes a 'v'-like bend,
    % where normal sampling and offsetting gives poor results for the parallel line
    % size of testcircle= size PenA/2 + 2* (distance between outer and inner line)
    % + PenC (inner line)
    testcircle := halfcircle scaled (.5*u/10+2*.125u+.5*u/10) shifted (0,.5*u/10);
    cur:=samplingdistance/2;
    count:=0;
    forever:
      t:= arctime cur of P;
      inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));

      %thdraw testcircle rotated (angle thdir(P,t)) shifted (point t of P) withpen (pencircle scaled 0.01u) ;
      if (xpart inter) >=0:
        % we are at a 'sharp bend', so set next point to intersectionpoint
        cur:=cur+samplingdistance;
        t := max( xpart inter, arctime cur of P);
        %thdraw point t of P withcolor 0.7*green;
        forever:
          t:= arctime cur of P;
          inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));
          exitif (xpart inter <0);
          cur := cur + samplingdistance;
          exitif (cur >=laenge);
        endfor;
        if (cur <laenge):
          inner[count]:=(point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
          innerdir[count]:=unitvector(thdir(P,t));
          count := count+1;
        fi;
      else:
        inner[count]:= (point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
        innerdir[count]:=unitvector(thdir(P,t));
        %thdraw inner[count] withpen PenD withcolor 0.5*red;
        count:=count +1;
        cur:= cur+ samplingdistance;
      fi;
      exitif (cur >=laenge);
    endfor;
    if count>2:
      % draw inner path
      pickup PenC;
      path innerpath;
      innerpath =
      for i=0 upto count-2:
        inner[i]{(innerdir[i])} ..
      endfor
      if cycle P: cycle;
      else:  inner[count-1];
      fi;
      thdraw innerpath;

    % draw the triangles

    path draw_triangle;
    pair l_triangle;

    laenge:= arclength innerpath;
    symsize:= adjust_step(laenge,0.5u);
    triangle_width:=symsize/2;
    cur:=(symsize/2);
    t := arctime (cur) of innerpath;
    t1:= arctime (cur-triangle_width/2) of innerpath;
    t2:= arctime (cur+triangle_width/2) of innerpath;
    l_triangle := (point t of innerpath);
    if ATTR__height >= 10: thfill else: thdraw fi (subpath (t1,t2) of innerpath) --
           ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
           --  cycle;

    for cur=(symsize/2) step symsize until laenge:
      t := arctime (cur) of innerpath;
      test := (point t of innerpath);
      my_dist := length(test-l_triangle);
      if (abs(my_dist-symsize) < 0.05u) or (my_dist>symsize):
         t1:= arctime (cur-triangle_width/2) of innerpath;
         t2:= arctime (cur+triangle_width/2) of innerpath;
	 draw_triangle:=(subpath (t1,t2) of innerpath) --
                        ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
                         --  cycle;
	 if xpart (draw_triangle intersectiontimes P) < 0:
	    if ATTR__height >= 10:
	      thfill draw_triangle;
	    else:
	      thclean draw_triangle;
	      thdraw draw_triangle;
	    fi;
	    l_triangle:= test;
	 fi;
      fi;
    endfor;

    fi;
enddef;


def l_wall_sand_AUT (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenC;
  forever:
    t := arctime cas of P;
    thdraw (((0.01u,0.01u)--origin) rotated uniformdeviate(360) shifted ((point t of P) + (uniformdeviate 1) * .4u
            * unitvector(thdir(P,t) rotated -90)));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;
  thdraw P;

enddef;

def l_wall_pebbles_AUT (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .18u);
  pickup PenC;
  q:=superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/45) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


let l_wall_clay_AUT = l_wall_sand_AUT;


def l_wall_debris_AUT (expr P) =
  T:=identity;
  pickup PenC;
  laenge := arclength P;
  path block;
  path old_block;

  cur := 0;
  t:= arctime cur of P;
  % draw first block
  old_block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.05u,.15u)--cycle));
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle(thdir(P,0)) shifted point t of P;
  thclean old_block;
  thdraw old_block;

  cur := cur + 0.9*block_width;
  t:= arctime cur of P;
	% proceed with path
    forever:
	  % generate random block
        block := punked (((-.25u,-.25u)--(0.25.u,-.25u)--(0.50u,0.01u)--(0.25u,.25u)--(-.25u,.25u)--cycle)
          randomized (u/4))
          scaled (uniformdeviate(0.3)+.4)
          rotated uniformdeviate(360);
	  % check width of block
        block_width := (xpart urcorner block - xpart ulcorner block);
        exitif cur > (laenge- 2.5*block_width/2);
        % find next position where the block fits in without intersecting the previous one
	  forever:
	    exitif xpart ( (block rotated angle(-direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
            cur:=cur+0.01u;
            t:= arctime cur of P;
            exitif cur > (laenge- 2.5*block_width/2);
          endfor;
        exitif cur > (laenge- 2.5*block_width/2);

        old_block:= block rotated angle(-direction t of P) shifted point t of P;
        thclean old_block;
        thdraw old_block;
        cur := cur + block_width/2;
        t:= arctime cur of P;
    endfor;
	t:= arctime laenge-eps of P;

	% generate last block
      block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.1u,.15u)--cycle));
     block_width := (xpart urcorner block - xpart ulcorner block);

	% scale last block to fit in the remaining gap
     scale_factor:=1.5*(laenge-cur)/block_width;
     forever:
           exitif scale_factor < 0;  % bruces stab at preventing endless loop at large scales
           exitif xpart ( (block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P)) intersectiontimes old_block) < 0;
           scale_factor:=scale_factor-0.01;
     endfor;
     if scale_factor > 0:
       thclean block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
       thdraw block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
     fi;
enddef;


def l_wall_blocks_AUT (expr P) =

  T:=identity;
  pickup PenC;
  laenge := arclength P;

  path block;
  path old_block;

  cur := 0;
  t:= arctime cur of P;

  % draw first block
  old_block := ( (.7u,-.35u)--(.85u,0.01u)--(.4u,.5u)--(.1u,.3u)--(-.0u,-.0u) );
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle( thdir(P,0) ) shifted point t of P;
  thclean (old_block--cycle);
  thdraw old_block;


  cur := cur + block_width/2;
  t:= arctime cur of P;
  forever:
    % generate random block
    block := punked ( ( (.8u,-.35u)--(.85u,0.01u)--(.6u,.4u)--(.1u,.1u)--(-.0u,-.3u) )
          randomized (0.3u) )
           scaled (uniformdeviate(0.3)+.65)
          rotated (uniformdeviate(45)-15);
    % check width of block
    block_width := (xpart urcorner block - xpart ulcorner block);

    exitif cur > (laenge- 3.5*block_width/2);
    % find next position where the block fits in without intersecting the previous one
    forever:
      exitif xpart ( ((block--cycle) rotated angle(direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
      cur:=cur+0.01u;
      t:= arctime cur of P;
      exitif cur > (laenge- 3.5*block_width/2);
    endfor;
    exitif cur > (laenge- 3.5*block_width/2);

    old_block:= block rotated angle(direction t of P) shifted point t of P;
    thclean (old_block--cycle);
    thdraw old_block;


    cur := cur + block_width/2;
    t:= arctime cur of P;
  endfor;

    % generate last block
    t:= arctime laenge-eps of P;
    block := (( (-.15u,-.35u)--(.0u,.0u)--(-.45u,.5u)--(-.75u,.3u)--(-.85u,-.0u)) );
    block_width := (xpart urcorner block - xpart ulcorner block);
    % scale last block to fit in the remaining gap
    scale_factor:=(laenge-cur)/block_width;
    forever:
	  exitif scale_factor < 0;
      exitif xpart ( ( (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P) ) intersectiontimes old_block) < 0;
      scale_factor:=scale_factor-0.001;
    endfor;
    if scale_factor > 0:
      thclean (block--cycle) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
      thdraw (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
    fi;
enddef;



def l_wall_ice_AUT (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .6u);
  pickup PenC;
  p := (-.15u,0)--(.15u,0);
  q := p rotated 90 shifted (.25u,.0u);
  picture symbol,test_symbol;
  symbol:= image (
             thdraw p;
             thdraw q;
             );
  path bound,old_bound,test_bound;
  begingroup;
    interim bboxmargin:=0;
    bound := bbox (symbol);
  endgroup;
  t := arctime (cas + mojkrok/2) of P;
  thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
  old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));

  forever:
    t := arctime (cas + mojkrok/2) of P;
    test_bound:= bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    if xpart ((old_bound) intersectiontimes (test_bound))<0:
      if xpart (P intersectiontimes (test_bound))<0:
        thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
        old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
      fi;
    fi;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  thdraw P;
enddef;


def l_wall_underlying_AUT (expr P) =
  T:=identity;
  pickup PenA;
  laenge:= arclength P;
  t1 := arctime (0.5u) of P;
  t2 := arctime (laenge-.5u) of P;
  thdraw (subpath (t1,t2) of P) dashed evenly scaled optical_zoom;
enddef;


def l_wall_overlying_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  t1 := arctime (0.25u) of P;
  t2 := arctime (laenge-.25u) of P;
  t3 :=arctime (laenge) of P;
  pickup pensquare scaled (3.5*u/10);
  thdraw (subpath (t1,t2) of P) withcolor background;
    pickup PenA;
  thdraw subpath(0,t1) of P;
  thdraw subpath(t2,t3) of P;
  thdraw (subpath (t1,t2) of P) dashed dashpattern(on 2bp off 2bp on .5bp off 2bp on 2bp) scaled optical_zoom;
enddef;

def l_wall_moonmilk_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_flowstone_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    thfill (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P) --
           (point t1 of P)--cycle;
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_pit_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.5u);
  triangle_width:=symsize/2;
  cur:=(symsize-triangle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t  := arctime (cur + triangle_width/2) of P;
    t2 := arctime (cur + triangle_width) of P;
    if ATTR__height >= 10:
      thfill (subpath (t1,t2) of P) --
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
        cycle;
    else:
      thclean (subpath (t1,t2) of P) --
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
        cycle;
      thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
        (point t1 of P);
    fi;
    cur := cur + symsize;
    exitif cur > laenge - (1*symsize/3); % for rounding errors
    t1:=arctime (cur) of P;
  endfor;
  thdraw P;
enddef;


let l_overhang_AUT = l_pit_AUT;

let l_floorstep_AUT = l_floorstep_UIS;

let l_contour_AUT =l_contour_SKBB;

let l_ceilingstep_AUT = l_ceilingstep_UIS;

let l_ceilingmeander_AUT = l_ceilingmeander_UIS;

def l_flowstone_AUT (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_survey_cave_AUT (expr P) =
  T:=identity;
  pair zz[];
  pickup PenD;
  thdraw P;
enddef;

%% points

def p_stalactite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u, .4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
      thdraw (0,.15u) -- (.15u,.4u);
    else:
      U:=(.175u, .175u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.35u;
      thdraw fullcircle scaled 0.35u;
    fi;
enddef;

let p_icestalactite_AUT = p_stalactite_AUT;

def p_stalagmite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
      thdraw (0,-.15u) -- (.15u,-.4u);
    else:
      U:=(.15u,.15u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icestalagmite_AUT = p_stalagmite_AUT;

def p_pillar_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.15u)--(0,-.15u);
      thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
      thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    else:
      U:=(.225u,.225u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.45u;
      thdraw fullcircle scaled 0.45u;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icepillar_AUT = p_pillar_AUT;

def p_crystal_AUT (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;

    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (45);
    thdraw p rotated (90);
    thdraw p rotated (135);

    thdrawoptions();

enddef;

def p_spring_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.1u)..(0,-.1u)..(.3u,.1u);
enddef;


def p_sink_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.1u)..(0,.1u)..(.3u,-.1u);
enddef;

def p_breakdownchoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.21u,.305u)--(.0u,-.305u)--(.21u,.305u);
enddef;

def p_sand_AUT (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=-0.1u step 0.2u until .15u:
        for j=-0.1u step 0.2u until .15u:
          thdraw p rotated uniformdeviate(360)
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    thdrawoptions();
enddef;

let p_clay_AUT  = p_sand_AUT;

def p_pebbles_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path qq;
    for i=-0.15u step 0.3u until .2u:
        for j=-0.15u step 0.3u until .2u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360)
             shifted ((i,j) randomized 0.15u);
           thdraw qq;
        endfor;
    endfor;
enddef;

def p_debris_AUT (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path block,q;
    block :=  ((-.15u,-.15u)--(.15u,-.15u)--(.3u,0.01u)--(.15u,.15u)--(-.15u,.15u)--cycle) ;

    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.15u);
    thclean q; thdraw q;

    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.15u,-0.15u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.15u))) rotated uniformdeviate(360) shifted (0.15u,-0.15u);
    thclean q; thdraw q;

enddef;

def p_blocks_AUT (expr pos,theta,sc,al)=
    U:=(u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;

    path block,q;
    block :=  ((-.25u,-.25u)--(.25u,-.25u)--(.5u,0.01u)--(.25u,.25u)--(-.25u,.25u)--cycle) ;

    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.25u);
    thclean q; thdraw q;

    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.25u,-0.25u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.3u))) rotated uniformdeviate(360) shifted (0.25u,-0.25u);
    thclean q; thdraw q;

enddef;

def p_water_AUT (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withcolor col_water_bg;
    thfill p withpattern pattern_water_AUT;
    thdraw p;
enddef;

def p_ice_AUT (expr pos,theta,sc,al)=
    U:=(.6u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    thdraw p rotated 90;
    thdraw p shifted (0.45u,.0u);
    thdraw p shifted (-0.45u,.0u);

    thdraw p rotated 90 shifted (-0.45u,0.25u);
    thdraw p shifted (0u,0.25u);
    thdraw p rotated 90 shifted (0.45u,.25u);
enddef;

def p_entrance_AUT (expr pos,theta,sc,al)=
    U:=(.3u,.75u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    path slice;
    for i= -0.5 step 0.01 until 0.5:
      slice:= (-.3u*(0.5-i),1.5*i*u)--(0,.75u)--(.3u*(0.5-i),1.5i*u)--cycle;
      thfill slice withcolor (min(0.95,0.5-1.75i),min(0.95,.5-1.75i),min(0.95,.5-1.75i));
    endfor;
    thdraw ((-.3u,-0.75u)--(0,.75u)--(.3u,-0.75u)--cycle);
enddef;

def p_gradient_AUT (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-0.5u)--(0,0.5u);
    p:=(-.15u,.3u)--(0,0.7u)--(.15u,.3u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_airdraught_AUT (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,.5u)--(0,-0.8u);
	p:=(-.2u,.2u)--(0,.55u)--(.2u,.2u)--cycle;
	thfill p;
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	  thdraw (0,-(1-0.2i)*u)--(-.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_station_temporary_AUT (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled 0.15u;
    thdraw fullcircle scaled 0.15u;
enddef;

let p_station_painted_AUT = p_station_fixed_ASF ;
let p_station_fixed_AUT = p_station_fixed_ASF ;

def p_claychoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.15u,.3u)--(-.15u,-.25u)--(.15u,-.25u);
enddef;

def p_claytree_AUT (expr pos,theta,sc,al)=
    U:=(.55u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= (-.15u,.15u)--(.0u,.6u)--(.15u,.15u);
    thdraw p ;
    thdraw p shifted (-.4u,-.3u);
    thdraw p shifted (.4u,-.2u) ;
enddef;




%%%%% ENDINPUT uAUT %%%%%





%%%%% INPUT uSBE %%%%%


% Symbol set of Brazilian Speleological Society (SBE - Sociedade Brasileira de
% Espeleologia), author Rodrigo Severo.


%%%%%%%%%%%%%%%%%%%%%%%%% Points %%%%%%%%%%%%%%%%%%%%%%%%%


picture SBE_altar_raw;
SBE_altar_raw := image(
	fill (406,482)..controls (364,491) and (340,542)..(360,581)
		..controls (378,621) and (436,633)..(469,603)
		..controls (504,575) and (500,514)..(461,491)
		..controls (445,480) and (425,478)..(406,482)
		--cycle;
	pickup pencircle scaled 99bp;
	draw (225,307)--(319,460);
	pickup pencircle scaled 70bp;
	draw (329,472)--(391,364)--(466,419);
	draw (154,188)--(326,188)--(224,290);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_altar_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_altar_raw;
enddef;


picture SBE_archeo_excavation_raw;
SBE_archeo_excavation_raw := image(
	begingroup;
		fill (199,415)--(242,555)--(312,574)
			--(329,558)--(351,580)--(335,597)
			--(422,683)--(466,640)--(379,553)
			--(362,569)--(340,547)--(359,528)
			--(339,457)--cycle;
		pickup pencircle scaled 17bp;
		interim linecap := rounded;
		draw (138,464)..controls (152,460) and (169,461)..(187,461);
		draw (368,463)..controls (411,458) and (449,461)..(489,464);
		pickup pencircle scaled 11bp;
		interim linecap := squared;
		draw (291,403)..controls (279,402) and (262,395)..(253,372);
		draw (371,409)..controls (370,422) and (359,429)..(346,430);
		draw (423,399)..controls (432,402) and (437,411)..(437,418);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_archeoexcavation_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_archeo_excavation_raw;
enddef;


picture SBE_audio_raw;
SBE_audio_raw := image(
	fill (125,196)--(81,171)--(44,171)
		..controls (34,171) and (27,163)..(27,154)
		--(27,115)..controls (27,106) and (34,98)..(44,98)
		--(81,98)--(125,73)..controls (133,68) and (140,72)..(140,81)
		--(140,188)..controls (140,197) and (133,201)..(125,196)
		--cycle;
	pickup pencircle scaled 11bp;
	draw (158,186)..controls (178,152) and (179,118)..(158,82);
	draw (185,202)..controls (208,166) and (213,112)..(185,67);
	draw (213,218)..controls (248,150) and (243,105)..(213,50);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_audio_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_audio_raw;
enddef;


picture SBE_bat_raw;
SBE_bat_raw := image(
	fill (538,34)..controls (484,144) and (350,326)..(287,197)
		..controls (249,375) and (141,347)..(83,352)
		..controls (58,356) and (10,339)..(53,371)
		..controls (100,409) and (147,451)..(204,474)
		..controls (286,503) and (318,471)..(376,407)
		..controls (439,342) and (510,278)..(599,252)
		..controls (601,278) and (580,480)..(623,338)
		..controls (621,373) and (696,393)..(707,345)
		..controls (719,377) and (741,417)..(737,370)
		..controls (732,310) and (745,281)..(749,252)
		..controls (837,323) and (902,458)..(1017,478)
		..controls (1114,499) and (1201,436)..(1266,371)
		..controls (1285,353) and (1316,330)..(1270,343)
		..controls (1174,357) and (1033,396)..(1018,231)
		..controls (905,326) and (818,126)..(798,41)
		..controls (718,124) and (662,-13)..(637,34)
		..controls (621,76) and (562,52)..(538,34)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_bat_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_bat_raw;
enddef;


picture SBE_bones_raw;
SBE_bones_raw := image(
	fill (328,272)..controls (258,226) and (188,192)..(132,134)
		..controls (119,115) and (103,80)..(80,78)
		..controls (68,76) and (49,83)..(39,93)
		..controls (35,97) and (15,102)..(25,118)
		..controls (44,150) and (30,150)..(18,154)
		..controls (6,159) and (-2,159)..(-3,168)
		..controls (2,202) and (32,206)..(54,205)
		..controls (83,204) and (94,199)..(126,215)
		..controls (148,226) and (183,243)..(278,300)
		--cycle;
	fill (663,585)..controls (648,585) and (632,579)..(620,571)
		..controls (609,563) and (597,547)..(587,527)
		..controls (571,497) and (555,479)..(529,463)
		..controls (506,448) and (493,443)..(445,412)
		--(501,378)..controls (544,403) and (605,415)..(650,416)
		..controls (671,416) and (672,416)..(683,422)
		..controls (708,436) and (714,455)..(701,474)
		..controls (674,489) and (653,488)..(674,511)
		..controls (686,524) and (702,548)..(698,562)
		..controls (692,578) and (679,585)..(663,585)
		--cycle;
	fill (584,155)..controls (572,180) and (570,192)..(541,213)
		..controls (506,237) and (222,404)..(158,436)
		..controls (118,456) and (92,463)..(43,466)
		..controls (22,468) and (21,468)..(10,474)
		..controls (-12,490) and (-17,510)..(-3,527)
		..controls (23,541) and (45,538)..(25,563)
		..controls (15,576) and (0,601)..(5,615)
		..controls (19,647) and (61,636)..(83,619)
		..controls (93,610) and (104,593)..(114,572)
		..controls (127,542) and (142,523)..(166,505)
		..controls (205,477) and (361,387)..(421,358)
		..controls (480,330) and (597,259)..(609,256)
		..controls (631,255) and (670,257)..(683,238)
		..controls (690,228) and (693,208)..(690,195)
		..controls (688,189) and (693,170)..(674,171)
		..controls (637,172) and (644,159)..(646,147)
		..controls (648,134) and (652,126)..(644,121)
		..controls (612,110) and (594,134)..(584,155)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_bones_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_bones_raw;
enddef;


def p_curtains_UIS(expr pos, theta, sc, al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
		thdraw (0,.15u)--(0,0){dir 180}..(-.12u,-.11u)..{dir 0}(0,-.22u)--(0,-.4u);
	endfor;
enddef;


picture SBE_danger_raw;
SBE_danger_raw := image(
	fill (331,489)..controls (330,489) and (328,489)..(326,488)
		--(291,422)..controls (291,422) and (291,421)..(291,421)
		..controls (291,417) and (294,414)..(297,413)
		--(365,413)..controls (369,414) and (371,417)..(371,421)
		..controls (371,422) and (371,422)..(371,423)
		--(336,488)..controls (335,489) and (333,489)..(331,489)
		..controls (331,489) and (331,489)..(331,489)
		--cycle withcolor red;
	fill (336,427)..controls (336,430) and (334,432)..(331,432)
		..controls (328,432) and (326,430)..(326,427)
		..controls (326,424) and (328,422)..(331,422)
		..controls (334,422) and (336,424)..(336,427)
		--cycle withcolor white;
	fill (335,464)..controls (336,466) and (332,466)..(331,466)
		..controls (330,466) and (327,466)..(327,464)
		--(330,436)..controls (330,435) and (330,435)..(331,435)
		..controls (332,435) and (332,435)..(332,436)
		--cycle withcolor white;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_danger_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_danger_raw;
enddef;


def p_discpillar_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (-.15u,.4u) -- (0,.15u) -- (0,-.15u) -- (-.15u,-.4u);
	thdraw (0,-.15u) -- (.15u,-.4u);
	thdraw (0,.15u) -- (.15u,.4u);
	thdraw (-.15u,0) -- (.15u,0);
enddef;


def p_discpillars_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u) -- (0,.15u) -- (0,-.15u) -- (-.15u,-.4u);
		thdraw (0,-.15u) -- (.15u,-.4u);
		thdraw (0,.15u) -- (.15u,.4u);
		thdraw (-.15u,0) -- (.15u,0);
	endfor;
enddef;


def p_discstalactites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
		thdraw (0,.15u) -- (.15u,.4u);
		thdraw (-.15u,-.1u) -- (.15u,-.1u);
	endfor;
enddef;


def p_discstalagmites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
		thdraw (0,-.15u) -- (.15u,-.4u);
		thdraw (-.15u,.1u) -- (.15u,.1u);
	endfor;
enddef;


def p_discstalactite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
	thdraw (0,.15u) -- (.15u,.4u);
	thdraw (-.15u,-.1u) -- (.15u,-.1u);
enddef;


def p_discstalagmite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
	thdraw (0,-.15u) -- (.15u,-.4u);
	thdraw (-.15u,.1u) -- (.15u,.1u);
enddef;


picture SBE_electric_light_raw;
SBE_electric_light_raw := image(
	begingroup;
		fill (334,564)..controls (341,561) and (346,556)..(349,550)
			..controls (350,548) and (351,546)..(351,543)
			..controls (349,543) and (347,543)..(345,543)
			..controls (329,543) and (313,543)..(296,543)
			..controls (294,545) and (296,548)..(297,550)
			..controls (300,556) and (305,561)..(312,564)
			..controls (317,567) and (324,567)..(330,565)
			..controls (332,565) and (333,565)..(334,564)
			--cycle;
		fill (394,393)..controls (402,379) and (406,361)..(404,344)
			..controls (399,312) and (375,287)..(348,280)
			..controls (317,271) and (282,283)..(263,310)
			..controls (246,333) and (244,370)..(258,391)
			..controls (277,419) and (281,466)..(281,466)
			--(368,466)..controls (369,439) and (383,413)..(394,393)
			--cycle;
		pickup pencircle scaled 25bp;
		draw (153,248)--(224,303);
		draw (489,255)--(424,301);
		draw (408,208)--(377,259);
		draw (241,218)--(266,265);
		draw (324,161)--(324,245);
		pickup pencircle scaled 22bp;
		interim linecap := rounded;
		draw (282,489)--(370,489);
		draw (280,524)--(371,524);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_electriclight_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_electric_light_raw;
enddef;


picture SBE_exvoto_raw;
SBE_exvoto_raw := image(
	pickup pencircle scaled 29bp;
	draw (274,659)--(381,623);
	draw (209,277)--(247,393);
	draw (187,282)--(228,270);
	draw (297,647)--(224,427)--(247,393)
		--(283,408)--(357,631);
	draw (251,497)--(302,494);
	draw (490,657)--(578,587);
	draw (297,321)--(373,417);
	draw (282,334)--(313,309);
	draw (508,638)--(363,457)--(373,417)
		--(412,418)--(558,602);
	draw (421,524)--(452,482);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_exvoto_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_exvoto_raw;
enddef;


picture SBE_gate_raw;
SBE_gate_raw := image(
	begingroup;
		pickup pencircle scaled 28bp;
		interim linecap := butt;
		interim linejoin := rounded;
		draw (121,221)--(249,244)--(249,546)
			--(121,454)--cycle;
		draw (466,221)--(337,244)--(337,546)
			--(465,454)--cycle;
		pickup pencircle scaled 22bp;
		interim linejoin := mitered;
		draw (121,307)--(249,330);
		draw (184,496)--(184,234);
		draw (466,307)--(337,330);
		draw (402,496)--(402,234);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_gate_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_gate_raw;
enddef;


def p_helictites_UIS(expr pos,theta,sc,al) =
	U:=(.4u,.8u);
	pickup PenC;
	for i=-1 upto 1:
		if i < 0:
			T:=identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .45u, abs(i) * .15u));
		else:
			T:=identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		fi;
		thdraw (0,.4u)--(0,-.4u);
		p := (-.2u,.4u)---(-.2u,.1u){down}..{dir -10}(-.1u,0.02u)---origin;
		thdraw p;
		thdraw p reflectedabout (origin,(0,u)) reflectedabout (origin,(u,0));
	endfor;
enddef;


picture SBE_human_bones_raw;
SBE_human_bones_raw := image(
	fill (52,279)..controls (50,279) and (48,279)..(47,278)
		--(47,278)..controls (37,276) and (32,266)..(33,258)
		..controls (26,254) and (20,247)..(20,240)
		..controls (20,230) and (30,221)..(41,221)
		..controls (45,222) and (49,223)..(52,225)
		--(88,205)..controls (88,205) and (88,206)..(87,206)
		--(86,210)..controls (82,221) and (81,236)..(82,251)
		--(72,257)..controls (72,261) and (71,265)..(70,268)
		..controls (66,275) and (59,279)..(52,279)
		--cycle;
	fill (258,151)..controls (256,139) and (255,125)..(249,113)
		--(296,87)..controls (295,79) and (300,71)..(306,67)
		..controls (323,63) and (335,72)..(335,86)
		..controls (342,90) and (347,97)..(347,104)
		..controls (347,114) and (337,123)..(326,122)
		..controls (322,122) and (319,121)..(315,119)
		--cycle;
	fill (316,279)..controls (309,279) and (302,275)..(298,268)
		..controls (296,265) and (296,261)..(296,257)
		--(291,254)..controls (293,239) and (292,221)..(288,210)
		--(288,209)--(315,225)..controls (319,223) and (322,222)..(327,221)
		..controls (338,221) and (347,230)..(347,240)
		..controls (347,247) and (342,254)..(335,258)
		..controls (335,266) and (331,276)..(321,278)
		--(321,278)..controls (319,279) and (318,279)..(316,279)
		--cycle;
	fill (116,155)--(52,119)..controls (49,121) and (46,122)..(41,122)
		..controls (30,123) and (20,114)..(20,104)
		..controls (20,97) and (25,90)..(33,86)
		..controls (32,72) and (44,63)..(62,67)
		..controls (67,71) and (72,79)..(72,87)
		--(123,116)..controls (118,128) and (117,143)..(116,155)
		--cycle;
	fill (187,311)..controls (179,311) and (171,310)..(165,308)
		..controls (136,296) and (120,285)..(109,255)
		..controls (105,242) and (105,223)..(109,211)
		--(110,208)..controls (119,188) and (127,188)..(129,184)
		..controls (135,174) and (130,139)..(148,126)
		..controls (156,124) and (165,119)..(171,120)
		..controls (176,122) and (182,120)..(187,120)
		..controls (192,120) and (198,121)..(203,120)
		..controls (211,120) and (218,123)..(226,126)
		..controls (244,139) and (239,174)..(245,184)
		..controls (246,188) and (255,188)..(263,208)
		--(265,211)..controls (269,223) and (269,242)..(265,255)
		..controls (265,255) and (259,272)..(249,282)
		..controls (236,295) and (230,302)..(209,308)
		..controls (203,310) and (195,311)..(187,311)
		--cycle;
	fill (171,230)..controls (162,217) and (161,207)..(148,207)
		..controls (125,206) and (126,224)..(125,231)
		..controls (123,240) and (136,248)..(148,248)
		..controls (159,248) and (176,239)..(171,230)
		--cycle withcolor white;
	fill (203,230)..controls (212,217) and (212,207)..(226,207)
		..controls (249,206) and (247,224)..(249,231)
		..controls (251,240) and (238,248)..(226,248)
		..controls (215,248) and (198,239)..(203,230)
		--cycle withcolor white;
	fill (187,212)..controls (177,207) and (175,183)..(175,174)
		..controls (175,174) and (176,173)..(177,173)
		..controls (186,178) and (189,178)..(198,173)
		..controls (199,173) and (200,174)..(200,174)
		..controls (200,183) and (197,213)..(187,212)
		--cycle withcolor white;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_humanbones_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_human_bones_raw;
enddef;


picture SBE_masonry_raw;
SBE_masonry_raw := image(
	begingroup;
		pickup pencircle scaled 28bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (287,482)--(355,482);
		draw (247,442)--(315,442);
		draw (327,442)--(395,442);
		draw (206,401)--(275,401);
		draw (287,401)--(355,401);
		draw (247,360)--(315,360);
		draw (327,360)--(395,360);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

def p_masonry_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_masonry_raw;
enddef;


picture UIS_minus_raw;
UIS_minus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,401)--(403,401);
	pickup pencircle scaled 2bp;
	draw (407,401)..controls (407,394) and (401,387)..(393,387)
		..controls (385,387) and (379,394)..(379,401)
		..controls (379,409) and (385,415)..(393,415)
		..controls (401,415) and (407,409)..(407,401)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_minus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_minus_raw;
enddef;


picture SBE_mud_raw;
SBE_mud_raw := image(
	fill (240,321)..controls (232,352) and (217,388)..(183,397)
		..controls (156,398) and (135,369)..(108,381)
		..controls (82,388) and (66,417)..(74,442)
		..controls (78,479) and (59,518)..(79,552)
		..controls (87,582) and (41,598)..(52,628)
		..controls (68,653) and (99,634)..(121,630)
		..controls (147,623) and (162,645)..(172,664)
		..controls (200,685) and (236,674)..(267,676)
		..controls (290,675) and (312,676)..(333,685)
		..controls (352,692) and (380,696)..(394,676)
		..controls (406,653) and (421,627)..(450,623)
		..controls (474,620) and (506,635)..(520,605)
		..controls (536,576) and (533,543)..(533,512)
		..controls (531,476) and (511,442)..(521,407)
		..controls (523,374) and (483,370)..(459,370)
		..controls (431,371) and (407,359)..(382,348)
		..controls (357,337) and (326,324)..(300,340)
		..controls (277,343) and (264,298)..(241,320)
		--(240,320)--cycle withcolor (0.53, 0.24, 0.02);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_mud_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_mud_raw;
enddef;


picture SBE_mudcrack_raw;
SBE_mudcrack_raw := image(
	fill (320,501)--(340,468)--(320,462)
		--(320,462)--(320,457)--(348,464)
		--(387,451)--(371,434)--(345,421)
		--(320,427)--(320,427)--(320,424)
		--(331,422)--(320,385)--(325,385)
		--(335,422)--(344,418)--(351,385)
		--(355,385)--(355,385)--(348,419)
		--(373,429)--(401,403)--(393,388)
		--(395,385)--(397,385)--(396,387)
		--(403,402)--(416,400)--(428,389)
		--(429,390)--(417,404)--(403,404)
		--(378,432)--(393,448)--(431,415)
		--(436,415)--(436,419)--(433,419)
		--(396,452)--(406,464)--(436,460)
		--(436,464)--(408,468)--(403,484)
		--(436,490)--(436,493)--(403,488)
		--(403,501)--(399,501)--(400,483)
		--(403,468)--(391,457)--(351,467)
		--(378,501)--(370,501)--(346,468)
		--(324,501)--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_mudcrack_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_mudcrack_raw;
enddef;


picture SBE_nameplate_raw;
SBE_nameplate_raw := image(
	pickup pencircle scaled 24bp;
	draw (77,563)--(505,563)--(505,340)
		--(77,340)--cycle;
	pickup pencircle scaled 10bp;
	draw (208,496)--(422,496);
	draw (117,450)--(358,450);
	draw (264,401)--(470,401);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_nameplate_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_nameplate_raw;
enddef;


picture SBE_wheelchair_raw;
SBE_wheelchair_raw := image(
	fill (363,192)..controls (363,97) and (286,20)..(192,20)
		..controls (97,20) and (20,97)..(20,192)
		..controls (20,287) and (97,364)..(192,364)
		..controls (286,364) and (363,287)..(363,192)
		--cycle withcolor white;
	pickup pencircle scaled 39bp;
	draw (363,192)..controls (363,97) and (286,20)..(192,20)
		..controls (97,20) and (20,97)..(20,192)
		..controls (20,287) and (97,364)..(192,364)
		..controls (286,364) and (363,287)..(363,192)
		--cycle withcolor red;
	fill (202,301)..controls (202,286) and (190,274)..(175,274)
		..controls (160,274) and (148,286)..(148,301)
		..controls (148,316) and (160,328)..(175,328)
		..controls (190,328) and (202,316)..(202,301)
		--cycle;
	pickup pencircle scaled 21bp;
	draw (139,221)..controls (109,212) and (88,184)..(88,152)
		..controls (88,113) and (120,81)..(160,81)
		..controls (192,81) and (221,102)..(229,133);
	draw (177,254)--(177,178)--(259,178)
		--(278,129)--(299,134);
	draw (177,233)--(239,233);
);

picture SBE_nowheelchair_raw;
SBE_nowheelchair_raw := image(
	draw SBE_wheelchair_raw;
	begingroup;
		pickup pencircle scaled 30bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (60,307)--(323,77) withcolor red;
	endgroup;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_nowheelchair_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_nowheelchair_raw;
enddef;


picture SBE_pendant_raw;
SBE_pendant_raw := image(
	pickup pencircle scaled 22bp;
	draw (476,639)..controls (471,639) and (422,621)..(428,575)
		..controls (434,533) and (506,503)..(505,457)
		..controls (502,260) and (383,164)..(289,164)
		..controls (196,164) and (77,260)..(73,457)
		..controls (72,503) and (144,533)..(150,575)
		..controls (156,621) and (107,639)..(102,639);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_pendant_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_pendant_raw;
enddef;


def p_pillarwithcurtains_UIS(expr pos, theta, sc, al) =
	U := (.15u,.5u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (0,.25u)--(0,.1u){dir 180}..(-.1u,0)..{dir 0}(0,-.1u)--(0,-.25u);
	thdraw (-.15u,-.5u)--(0,-.25u)--(.15u,-.5u);
	thdraw (-.15u,.5u)--(0,.25u)--(.15u,.5u);
enddef;


def p_pillarswithcurtains_UIS(expr pos, theta, sc, al) =
	U := (.3u,u);
	pickup PenC;
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (0,.25u)--(0,.1u){dir 180}..(-.1u,0)..{dir 0}(0,-.1u)--(0,-.25u);
		thdraw (-.15u,-.5u)--(0,-.25u)--(.15u,-.5u);
		thdraw (-.15u,.5u)--(0,.25u)--(.15u,.5u);
	endfor;
enddef;


picture SBE_photo_raw;
SBE_photo_raw := image(
	fill (186,476)--(186,445)--(111,445)
		--(75,408)--(75,302)--(188,302)
		--(188,286)--(329,286)--(329,302)
		--(440,302)--(440,408)--(405,445)
		--(328,445)--(328,476)--cycle;
	pickup pencircle scaled 18bp;
	draw (194,499)--(107,621);
	draw (320,499)--(407,621);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_photo_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_photo_raw;
enddef;


picture UIS_plus_raw;
UIS_plus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,401)--(403,401);
	draw (393,411)--(393,392);
	pickup pencircle scaled 2bp;
	draw (407,401)..controls (407,394) and (401,387)..(393,387)
		..controls (385,387) and (379,394)..(379,401)
		..controls (379,409) and (385,415)..(393,415)
		..controls (401,415) and (407,409)..(407,401)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_plus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_plus_raw;
enddef;


picture UIS_plusminus_raw;
UIS_plusminus_raw := image(
	pickup pencircle scaled 3bp;
	draw (383,427)--(403,427);
	draw (393,418)--(393,437);
	draw (383,401)--(403,401);
	pickup pencircle scaled 2bp;
	draw (393,387)..controls (385,387) and (379,394)..(379,401)
		--(379,427)..controls (379,435) and (385,441)..(393,441)
		..controls (401,441) and (407,435)..(407,427)
		--(407,401)..controls (407,394) and (401,387)..(393,387)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / (xpart urcorner currentpicture) - (xpart llcorner currentpicture));
);

def p_plusminus_UIS(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw UIS_plusminus_raw;
enddef;


picture SBE_seed_germination_raw;
SBE_seed_germination_raw := image(
	fill (443,464)..controls (441,492) and (411,512)..(389,501)
		..controls (406,574) and (355,622)..(378,509)
		..controls (350,513) and (331,473)..(333,452)
		..controls (350,440) and (374,461)..(381,474)
		..controls (382,466) and (417,441)..(443,464)
		--cycle;
	pickup pencircle scaled 25bp;
	draw (101,276)..controls (177,243) and (396,296)..(502,269);
	pickup pencircle scaled 19bp;
	draw (194,270)..controls (160,669) and (364,759)..(382,543);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_seedgermination_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_seed_germination_raw;
enddef;


def p_stalactitestalagmite_UIS(expr pos,theta,sc,al) =
	U := (.15u, .4u);
	T := identity rotated theta aligned al scaled sc shifted pos;
	pickup PenC;
	thdraw (-.15u,.4u) -- (0,.2u) -- (.15u,.4u);
	thdraw (.15u,-.4u) -- (0,-.2u) -- (-.15u,-.4u);
	thdraw (0,-.2u) -- (0,-.1u);
	thdraw (0,.2u) -- (0,.1u);
enddef;


def p_stalactitesstalagmites_UIS(expr pos,theta,sc,al) =
	U := (.3u, .8u);
	pickup PenC;
	for i=-1 upto 1:
		T := identity rotated theta aligned al scaled (sc * 0.7) shifted (pos + (i * .3u, abs(i) * .15u));
		thdraw (-.15u,.4u) -- (0,.2u) -- (.15u,.4u);
		thdraw (.15u,-.4u) -- (0,-.2u) -- (-.15u,-.4u);
		thdraw (0,-.2u) -- (0,-.1u);
		thdraw (0,.2u) -- (0,.1u);
	endfor;
enddef;


picture SBE_tree_trunk_raw;
SBE_tree_trunk_raw := image(
	pickup pencircle scaled 11bp;
	draw (338,554)--(153,393)..controls (64,292) and (204,143)..(312,243)
		--(504,488);
	pickup pencircle scaled 0.1bp;
	fill (313,318)..controls (313,274) and (277,238)..(232,238)
		..controls (188,238) and (152,274)..(152,318)
		..controls (152,363) and (188,398)..(232,398)
		..controls (277,398) and (313,363)..(313,318)
		--cycle;
	pickup pencircle scaled 5bp;
	draw (290,453)--(348,506);
	draw (375,406)--(445,481);
	draw (316,397)--(348,429);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_treetrunk_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_tree_trunk_raw;
enddef;


picture SBE_volcano_raw;
SBE_volcano_raw := image(
	pickup pencircle scaled 21bp;
	draw (36,222)--(169,567)..controls (177,510) and (212,485)..(265,485)
		..controls (319,485) and (353,510)..(361,567)
		--(494,222);
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_volcano_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_volcano_raw;
enddef;


picture SBE_walkway_raw;
SBE_walkway_raw := image(
	begingroup;
		pickup pencircle scaled 9bp;
		interim linecap := butt;
		interim linejoin := mitered;
		draw (19,26)--(171,26);
		draw (135,61)--(171,61);
		draw (19,61)--(55,61);
		draw (89,61)--(104,61);
		pickup pencircle scaled 12bp;
		interim linecap := rounded;
		draw (63,43)--(79,72)--(93,135);
		draw (124,44)--(115,72)--(93,97)
			--(100,133);
		pickup pencircle scaled 9bp;
		interim linejoin := rounded;
		draw (133,109)--(115,117)--(99,144)
			--(72,128)--(62,107);
		pickup pencircle scaled 0.1bp;
		fill (113,162)..controls (113,157) and (108,152)..(102,152)
			..controls (96,152) and (91,157)..(91,162)
			..controls (91,168) and (96,173)..(102,173)
			..controls (108,173) and (113,168)..(113,162)
			--cycle;
	endgroup;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_walkway_SBE(expr pos, theta, sc, al) =
	T := identity rotated theta aligned al scaled sc shifted pos;
	thdraw SBE_walkway_raw;
enddef;


picture SBE_water_drip_raw;
SBE_water_drip_raw := image(
	fill (493,1196)..controls (535,1234) and (583,1266)..(635,1290)
		..controls (595,1233) and (566,1160)..(588,1091)
		..controls (622,981) and (733,912)..(757,796)
		..controls (789,684) and (728,556)..(622,509)
		..controls (524,461) and (398,489)..(328,572)
		..controls (278,629) and (259,710)..(272,785)
		..controls (293,942) and (375,1090)..(493,1196)
		--cycle;
	fill (495,1159)..controls (403,1066) and (329,950)..(299,821)
		..controls (287,761) and (285,694)..(314,637)
		..controls (354,571) and (425,522)..(502,512)
		..controls (513,511) and (550,509)..(522,518)
		..controls (449,551) and (384,613)..(366,694)
		..controls (342,794) and (371,898)..(411,990)
		..controls (441,1059) and (481,1123)..(524,1185)
		..controls (514,1177) and (505,1168)..(495,1159)
		--cycle withcolor white;
	fill (353,484)..controls (341,488) and (325,494)..(316,504)
		..controls (300,537) and (261,574)..(232,540)
		..controls (209,503) and (241,469)..(276,471)
		..controls (299,473) and (344,478)..(353,484)
		--cycle;
	fill (702,500)..controls (714,503) and (731,509)..(739,520)
		..controls (756,553) and (795,591)..(825,557)
		..controls (848,519) and (816,485)..(780,486)
		..controls (757,488) and (711,493)..(702,500)
		--cycle;
	fill (290,571)..controls (279,580) and (262,592)..(246,594)
		..controls (203,588) and (140,602)..(154,654)
		..controls (176,701) and (231,693)..(253,656)
		..controls (266,632) and (291,584)..(290,571)
		--cycle;
	fill (761,591)..controls (772,601) and (789,613)..(805,614)
		..controls (848,609) and (911,623)..(897,674)
		..controls (875,721) and (820,713)..(798,676)
		..controls (785,652) and (760,604)..(761,591)
		--cycle;
	currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
);

def p_waterdrip_SBE(expr pos, theta, sc, al) =
	T := identity aligned al rotated theta scaled sc shifted pos;
	thdraw SBE_water_drip_raw;
enddef;


def p_wheelchair_SBE(expr pos, theta, sc, al) =
	T := identity aligned al rotated theta scaled sc shifted pos;
	thdraw SBE_wheelchair_raw shifted (-(llcorner SBE_wheelchair_raw)-(urcorner SBE_wheelchair_raw - llcorner SBE_wheelchair_raw)/2) scaled (u / max((xpart urcorner SBE_wheelchair_raw) - (xpart llcorner SBE_wheelchair_raw), (ypart urcorner SBE_wheelchair_raw) - (ypart llcorner SBE_wheelchair_raw)));
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%% Lines %%%%%%%%%%%%%%%%%%%%%%%%%


def l_abyssentrance_SBE(expr P) =
	begingroup
		path SBE_Tick, SBE_T;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tick := (0,0.1u) -- (0,-0.1u);
		SBE_T := (0,0) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/8) of P;
			t2 := arctime (cursor + elementSize * 2/8) of P;
			t3 := arctime (cursor + elementSize * 4/8) of P;
			t4 := arctime (cursor + elementSize * 6/8) of P;
			t5 := arctime (cursor + elementSize * 7/8) of P;

			thdraw SBE_Tick rotated angle(thdir(P,t1)) shifted (point t1 of P);
			thdraw (subpath (t2,t4) of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);
			thdraw SBE_Tick rotated angle(thdir(P,t5)) shifted (point t5 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_dripline_SBE(expr P) =
	begingroup
		path SBE_Tick;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tick := (0,0.1u) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/8) of P;
			t2 := arctime (cursor + elementSize * 2/8) of P;
			t3 := arctime (cursor + elementSize * 4/8) of P;
			t4 := arctime (cursor + elementSize * 6/8) of P;
			t5 := arctime (cursor + elementSize * 7/8) of P;

			thdraw SBE_Tick rotated angle(thdir(P,t1)) shifted (point t1 of P);
			thdraw (subpath (t2,t4) of P);
			thdraw SBE_Tick rotated angle(thdir(P,t5)) shifted (point t5 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_fault_SBE(expr P) =
	begingroup
		path SBE_Dot;
		pair SBE_Ppb, SBE_Pdb, SBE_Pvb, SBE_Ppe, SBE_Pde, SBE_Pve;

		T := identity;

		pickup PenA;
		thdraw P;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Dot := (0,-0.05u) -- (0,0.05u);
		pickup PenC;
		distance := 0.2u;
		forever:
			t0 := arctime (cursor + elementSize * 1/8) of P;
			t1 := arctime (cursor + elementSize * 5/8) of P;
			t2 := arctime (cursor + elementSize * 7/8) of P;

			SBE_Ppb := (point t0 of P);
			SBE_Pdb := unitvector(thdir(P,t0));
			SBE_Pvb := SBE_Pdb rotated -90;
			SBE_Ppe := (point t1 of P);
			SBE_Pde := unitvector(thdir(P,t1));
			SBE_Pve := SBE_Pde rotated -90;

			if cursor > 0:
				thdraw (SBE_Ppb - distance * SBE_Pvb) -- (SBE_Ppe - distance * SBE_Pve);
			fi;

			thdraw SBE_Dot rotated (angle(thdir(P,t2))+90) shifted (point t2 of P + distance * unitvector(thdir(P,t2) rotated 90));

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_joint_SBE(expr P) =
	T := identity;

	cursor := 0;
	totalLength := arclength P;
	elementSize := adjust_step(totalLength, u); % symbol length nudged to be multiple of path length
	pickup PenC;
	forever:
		t0 := arctime (cursor + elementSize * 3/22) of P;
		t1 := arctime (cursor + elementSize * 10/22) of P;
		t2 := arctime (cursor + elementSize * 16/22) of P;
		t3 := arctime (cursor + elementSize * 19/22) of P;

		thdraw (subpath (t0,t1) of P);
		thdraw (subpath (t2,t3) of P);

		cursor := cursor + elementSize;
		exitif cursor > totalLength - (elementSize / 2);
	endfor;
enddef;


def l_lowceiling_SBE(expr P) =
	begingroup
		path SBE_T;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_T := (0,0) -- (0,-0.1u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/7) of P;
			t2 := arctime (cursor + elementSize * 3/7) of P;
			t3 := arctime (cursor + elementSize * 4/7) of P;
			t4 := arctime (cursor + elementSize * 6/7) of P;

			thdraw (subpath (t1,t4) of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t2))) shifted (point t2 of P);
			thdraw SBE_T rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_pitchimney_SBE(expr P) =
	begingroup
		path SBE_Tsmall, SBE_Tlarge;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length
		SBE_Tsmall := (0,0) -- (0,-0.1u);
		SBE_Tlarge := (0,0) -- (0,-0.175u);
		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/6) of P;
			t2 := arctime (cursor + elementSize * 2/6) of P;
			t3 := arctime (cursor + elementSize * 3/6) of P;
			t4 := arctime (cursor + elementSize * 4/6) of P;
			t5 := arctime (cursor + elementSize * 5/6) of P;

			thdraw (subpath (t1,t5) of P);

			thdraw SBE_Tsmall rotated (180+angle(thdir(P,t2))) shifted (point t2 of P);
			thdraw SBE_Tlarge rotated (180+angle(thdir(P,t3))) shifted (point t3 of P);
			thdraw SBE_Tsmall rotated (180+angle(thdir(P,t4))) shifted (point t4 of P);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


def l_rimstonedam_SBE(expr P) =
	cas := 0;
	distance := arclength P;
	mystep := adjust_step(distance, 0.9u);
	pickup PenC;
	forever:
		t  := arctime (cas + mystep/2) of P;
		T := identity rotated angle(thdir(P,t)) scaled 0.7 shifted (point t of P);
		thdraw (-.45u,.2u){dir -80}..{dir -50}(-.15u,0){dir 30}..{dir -30}(.15u,.1u){dir -50}..{dir 70}(.45u,.2u);
		cas := cas + mystep;
		exitif cas > distance - (2*mystep/3); % for rounding errors
	endfor;
enddef;


def l_rimstonepool_SBE(expr P) =
	cas := 0;
	distance := arclength P;
	mystep := adjust_step(distance, 0.9u);
	pickup PenC;
	forever:
		t  := arctime (cas + mystep/2) of P;
		T := identity rotated angle(thdir(P,t)) scaled 0.7 shifted (point t of P);
		p := (-.45u,.2u){dir -80}..{dir -50}(-.15u,-.1u){dir 30}..{dir -30}(.15u,.1u){dir -50}..{dir 70}(.45u,.2u);
		thfill buildcycle(p,((.5u,.15u)--(-.5u,.15u)));
		thdraw p;
		cas := cas + mystep;
		exitif cas > distance - (2*mystep/3); % for rounding errors
	endfor;
enddef;


def l_walkway_SBE(expr P) =
	begingroup
		pair SBE_da, SBE_db, SBE_pa, SBE_pb, SBE_ta, SBE_tb, SBE_tc, SBE_td;

		T := identity;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.2u); % symbol length nudged to be multiple of path length
		distance := 0.1u;

		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize * 1/5) of P;
			t2 := arctime (cursor + elementSize * 4/5) of P;

			SBE_pa := point t1 of P;
			SBE_pb := point t2 of P;

			SBE_da := unitvector(thdir(P,t1)) * distance;
			SBE_db := unitvector(thdir(P,t2)) * distance;

			SBE_ta := SBE_pa + (SBE_da rotated 90);
			SBE_tb := SBE_pb + (SBE_db rotated 90);
			SBE_tc := SBE_pa + (SBE_da rotated -90);
			SBE_td := SBE_pb + (SBE_db rotated -90);

			thdraw SBE_ta -- SBE_tb;
			thdraw SBE_tc -- SBE_td;

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;
	endgroup;
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%% Areas %%%%%%%%%%%%%%%%%%%%%%%%%


picture SBE_a_mudcrack_raw;
SBE_a_mudcrack_raw := image(
	begingroup;
		interim linecap := butt;
		interim linejoin := mitered;
		pickup pencircle scaled 8bp;
		draw (172,466)--(225,425)--(271,440)
			--(323,390)--(346,423)--(414,363)
			--(390,275)--(414,281)--(438,322);
		pickup pencircle scaled 4bp;
		draw (244,252)--(232,272)--(308,293)
			--(257,310)--(266,357)--(291,380)
			--(303,428)--(282,477)--(393,502)
			--(380,518);
		pickup pencircle scaled 6bp;
		draw (172,466)--(244,518);
		pickup pencircle scaled 8bp;
		draw (173,322)--(205,357)--(244,322)
			--(266,357);
		pickup pencircle scaled 8bp;
		draw (380,252)--(364,292)--(380,322)
			--(346,423)--(417,491)--(393,502);
		pickup pencircle scaled 8bp;
		draw (437,466)--(417,491)--(380,392);
		currentpicture := currentpicture shifted (-(llcorner currentpicture)-(urcorner currentpicture - llcorner currentpicture)/2) scaled (1.5u / max((xpart urcorner currentpicture) - (xpart llcorner currentpicture), (ypart urcorner currentpicture) - (ypart llcorner currentpicture)));
	endgroup;
);

beginpattern(pattern_mudcrack_SBE);
	draw SBE_a_mudcrack_raw;
endpattern;

def a_mudcrack_SBE(expr Path) =
	T := identity;
	thclean Path;
	thfill Path withpattern pattern_mudcrack_SBE;
enddef;


def pillar_main_SBE(expr P) =
	begingroup
		rgbcolor SBE_Orange;
		pair SBE_d, SBE_p;

		T := identity;

		SBE_Orange := (1, 0.6, 0);

		pickup PenD;
		thfill P withcolor SBE_Orange;

		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.01u); % symbol length nudged to be multiple of path length
		borderWidth := 0.3u;

		pickup PenA;
		forever:
			t1 := arctime (cursor + elementSize / 2) of P;

			SBE_p := point t1 of P;

			SBE_d := unitvector(thdir(P,t1)) * borderWidth;

			thdraw SBE_p -- SBE_p + (SBE_d rotated 90) withcolor white;;

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 2);
		endfor;

		pickup PenA;
		thdraw P withcolor SBE_Orange;
	endgroup;
enddef;

def a_pillar_SBE(expr P) =
	picture SBE_Pillar;

	SBE_Pillar := image(pillar_main_SBE(P));

	thdraw SBE_Pillar;
enddef;


def a_pillarwithcurtains_SBE(expr P) =
	begingroup
		picture SBE_Pillar;
		path SBE_Curtain;

		SBE_Pillar := image(pillar_main_SBE(P));

		thdraw SBE_Pillar;

		SBE_Curtain := (0,-.4u){dir 180}..(-0.1u,-0.3u)..{dir 0}(0,-0.2u)..(0.1u,-0.1u)..{dir -180}(0,0);
		SBE_Curtain := SBE_Curtain scaled (0.2 / 0.4);
		cursor := 0;
		totalLength := arclength P;
		elementSize := adjust_step(totalLength, 0.5u); % symbol length nudged to be multiple of path length

		pickup PenD;
		forever:
			t1 := arctime (cursor + elementSize / 2) of P;

			thdraw SBE_Curtain rotated (180+angle(thdir(P,t1))) shifted (point t1 of P) withcolor (1,0.6,0);

			cursor := cursor + elementSize;
			exitif cursor > totalLength - (elementSize / 3);
		endfor;
	endgroup;
enddef;


def a_stalactite_SBE(expr P) =
	T := identity;

	pickup PenA;
	thfill P withcolor (1, 0.9, 0.67);
	thdraw P withcolor (1, 0.6, 0);
enddef;


def a_stalactitestalagmite_SBE(expr P) =
	begingroup
		rgbcolor SBE_Orange, SBE_LightOrange;

		picture SBE_PicFill, SBE_PicDraw;
		path SBE_bboxP, SBE_clipFill, SBE_clipDraw;

		T := identity;

		SBE_LightOrange := (1, 0.9, 0.67);
		SBE_Orange := (1, 0.6, 0);
		SBE_bboxP := bbox P;
		SBE_clipFill := ulcorner SBE_bboxP -- llcorner SBE_bboxP -- lrcorner SBE_bboxP -- cycle;
		SBE_clipDraw := ulcorner SBE_bboxP -- urcorner SBE_bboxP -- lrcorner SBE_bboxP -- cycle;

		pickup PenA;
		thclean P;

		SBE_PicFill := image(
			fill P withcolor SBE_Orange;
			draw P withcolor SBE_Orange;
		);
		clip SBE_PicFill to SBE_clipFill;
		drawoptions();
		draw SBE_PicFill;

		SBE_PicDraw := image(
			fill P withcolor SBE_LightOrange;
			draw P withcolor SBE_Orange;
		);
		clip SBE_PicDraw to SBE_clipDraw;
		drawoptions();
		draw SBE_PicDraw;
	endgroup;
enddef;


def a_stalagmite_SBE(expr P) =
	T := identity;

	pickup PenA;
	thfill P withcolor (1, 0.6, 0);
enddef;



%%%%% ENDINPUT uSBE %%%%%






%%%%% INPUT thTrans %%%%%


% default translations

let p_station_fixed = p_station_fixed_ASF;
let p_station_painted = p_station_painted_SKBB;
let p_station_natural = p_station_natural_ASF;
let p_station_temporary = p_station_temporary_ASF;

let p_waterflow_paleo = p_waterflow_paleo_UIS;
let p_waterflow_permanent = p_waterflow_permanent_UIS;
let p_waterflow_intermittent = p_waterflow_intermittent_UIS;

let p_stalactite = p_stalactite_UIS;
let p_stalagmite = p_stalagmite_UIS;
let p_pillar = p_pillar_UIS;
let p_icestalactite = p_icestalactite_AUT;
let p_icestalagmite = p_icestalagmite_AUT;
let p_icepillar = p_icepillar_AUT;
let p_curtain = p_curtain_UIS;
let p_helictite = p_helictite_UIS;
let p_sodastraw = p_sodastraw_UIS;
let p_crystal = p_crystal_UIS;
let p_flowstone = p_flowstone_UIS;
let p_moonmilk = p_moonmilk_UIS;
let p_wallcalcite = p_wallcalcite_UIS;
let p_popcorn = p_popcorn_UIS;
let p_disk = p_disk_UIS;
let p_gypsum = p_gypsum_NSS;
let p_aragonite = p_aragonite_NSS;
let p_cavepearl = p_cavepearl_SKBB;
let p_gypsumflower = p_gypsumflower_NSS;
let p_rimstonepool = p_rimstonepool_ASF;
let p_rimstonedam = p_rimstonedam_ASF;
let p_anastomosis = p_anastomosis_UIS;
let p_karren = p_karren_UIS;
let p_scallop = p_scallop_UIS;
let p_flute = p_flute_UIS;
let p_raft = p_raft_NSS;
let p_raftcone = p_raftcone_NSS;
let p_spring = p_spring_SKBB;
let p_sink = p_sink_SKBB;
let p_narrowend = p_narrowend_UIS;
let p_lowend = p_lowend_UIS;
let p_flowstonechoke = p_flowstonechoke_NSS;
let p_breakdownchoke = p_breakdownchoke_NSS;
let p_claychoke = p_claychoke_AUT;
let p_claytree = p_claytree_AUT;
let p_bedrock = p_bedrock_ASF;
let p_clay = p_clay_SKBB;
let p_sand = p_sand_UIS;
let p_pebbles = p_pebbles_UIS;
let p_debris = p_debris_UIS;
let p_blocks = p_blocks_UIS;
let p_water = p_water_UIS;
let p_ice = p_ice_UIS;
let p_snow = p_snow_SKBB;
let p_archeomaterial = p_archeomaterial_UIS;
let p_paleomaterial = p_paleomaterial_UIS;
let p_guano = p_guano_UIS;
let p_altar = p_altar_SBE;
let p_archeoexcavation = p_archeoexcavation_SBE;
let p_audio = p_audio_SBE;
let p_bat = p_bat_SBE;
let p_bones = p_bones_SBE;
let p_curtains = p_curtains_UIS;
let p_danger = p_danger_SBE;
let p_discpillar = p_discpillar_UIS;
let p_discpillars = p_discpillars_UIS;
let p_discstalactites = p_discstalactites_UIS;
let p_discstalagmites = p_discstalagmites_UIS;
let p_discstalactite = p_discstalactite_UIS;
let p_discstalagmite = p_discstalagmite_UIS;
let p_electriclight = p_electriclight_SBE;
let p_exvoto = p_exvoto_SBE;
let p_gate = p_gate_SBE;
let p_helictites = p_helictites_UIS;
let p_humanbones = p_humanbones_SBE;
let p_masonry = p_masonry_SBE;
let p_minus = p_minus_UIS;
let p_mud = p_mud_SBE;
let p_mudcrack = p_mudcrack_SBE;
let p_nameplate = p_nameplate_SBE;
let p_nowheelchair = p_nowheelchair_SBE;
let p_pendant = p_pendant_SBE;
let p_pillarwithcurtains = p_pillarwithcurtains_UIS;
let p_pillarswithcurtains = p_pillarswithcurtains_UIS;
let p_photo = p_photo_SBE;
let p_plus = p_plus_UIS;
let p_plusminus = p_plusminus_UIS;
let p_seedgermination = p_seedgermination_SBE;
let p_stalactitestalagmite = p_stalactitestalagmite_UIS;
let p_stalactitesstalagmites = p_stalactitesstalagmites_UIS;
let p_treetrunk = p_treetrunk_SBE;
let p_volcano = p_volcano_SBE;
let p_walkway = p_walkway_SBE;
let p_waterdrip = p_waterdrip_SBE;
let p_wheelchair = p_wheelchair_SBE;
let p_vegetabledebris = p_vegetabledebris_ASF;
let p_root = p_root_ASF;
let p_entrance = p_entrance_UIS;
let p_gradient = p_gradient_UIS;
let p_rope = p_rope_SKBB;
let p_fixedladder = p_fixedladder_SKBB;
let p_ropeladder = p_ropeladder_SKBB;
let p_steps = p_steps_SKBB;
let p_bridge = p_bridge_SKBB;
let p_traverse = p_traverse_SKBB;
let p_anchor = p_anchor_SKBB;
let p_camp = p_camp_SKBB;
let p_dig = p_dig_UIS;
let p_noequipment = p_noequipment_SKBB;
let p_sectionarrow = p_sectionarrow_SKBB;
let p_continuation = p_continuation_UIS;
let p_airdraught = p_airdraught_UIS;
let p_airdraught_winter = p_airdraught_winter_UIS;
let p_airdraught_summer = p_airdraught_summer_UIS;
let p_station = p_station_SKBB;
let p_handrail = p_handrail_SKBB;
let p_viaferrata = p_viaferrata_SKBB;
let p_stalactites = p_stalactites_UIS;
let p_stalagmites = p_stalagmites_UIS;
let p_pillars = p_pillars_UIS;
let l_abyssentrance = l_abyssentrance_SBE;
let l_dripline = l_dripline_SBE;
let l_fault = l_fault_SBE;
let l_joint = l_joint_SBE;
let l_lowceiling = l_lowceiling_SBE;
let l_pitchimney = l_pitchimney_SBE;
let l_rimstonedam = l_rimstonedam_SBE;
let l_rimstonepool = l_rimstonepool_SBE;
let l_walkway = l_walkway_SBE;

let l_wall_bedrock = l_wall_bedrock_UIS;
let l_wall_sand = l_wall_sand_SKBB;
let l_wall_clay = l_wall_clay_SKBB;
let l_wall_pebbles = l_wall_pebbles_SKBB;
let l_wall_debris = l_wall_debris_SKBB;
let l_wall_blocks = l_wall_blocks_SKBB;
let l_wall_ice = l_wall_ice_SKBB;
let l_wall_underlying = l_wall_underlying_UIS;
let l_wall_unsurveyed = l_wall_unsurveyed_SKBB;
let l_wall_presumed = l_wall_presumed_UIS;
%let l_wall_invisible = l_wall_invisible;
let l_wall_pit = l_wall_pit_AUT;
let l_wall_overlying = l_wall_overlying_AUT;
let l_wall_flowstone = l_wall_flowstone_AUT;
let l_wall_moonmilk = l_wall_moonmilk_AUT;

let l_waterflow_permanent = l_waterflow_permanent_UIS;
let l_waterflow_intermittent = l_waterflow_intermittent_SKBB;
let l_waterflow_conjectural = l_waterflow_conjectural_SKBB;

let l_border_visible = l_border_visible_SKBB;
let l_border_temporary = l_border_temporary_SKBB;
let l_border_presumed = l_border_presumed_SKBB;
%let l_border_invisible = l_border_invisible;

let l_floorstep = l_floorstep_UIS;
let l_pit = l_pit_UIS;
let l_ceilingstep = l_ceilingstep_SKBB;
let l_chimney = l_chimney_UIS;
let l_overhang = l_overhang_SKBB;
let l_slope = l_slope_SKBB;
let l_ceilingmeander = l_ceilingmeander_SKBB;
let l_floormeander = l_floormeander_SKBB;
let l_contour = l_contour_SKBB;
let l_rockborder = l_rockborder_UIS;
let l_rockedge = l_rockedge_UIS;
let l_flowstone = l_flowstone_UIS;
let l_moonmilk = l_moonmilk_UIS;
let l_section = l_section_SKBB;
let l_survey_cave = l_survey_cave_SKBB;
let l_survey_surface = l_survey_surface_SKBB;
let l_arrow = l_arrow_SKBB;
let l_gradient = l_gradient_UIS;
let l_mapconnection = l_mapconnection_SKBB;
let l_handrail = l_handrail_SKBB;
let l_steps = l_steps_SKBB;
let l_fixedladder = l_fixedladder_SKBB;
let l_ropeladder = l_ropeladder_SKBB;
let l_rope = l_rope_SKBB;
let l_viaferrata = l_viaferrata_SKBB;

let a_water = a_water_UIS;
let a_sump = a_sump_UIS;
let a_sand = a_sand_UIS;
let a_debris = a_debris_SKBB;
let a_blocks = a_blocks_SKBB;
let a_snow = a_snow_SKBB;
let a_ice = a_ice_SKBB;
let a_pebbles = a_pebbles_SKBB;
let a_clay = a_clay_SKBB;
let a_bedrock = a_bedrock_SKBB;
let a_flowstone = a_flowstone_ASF;
let a_moonmilk = a_moonmilk_SKBB;
let a_dimensions = a_dimensions_SKBB;
let a_mudcrack = a_mudcrack_SBE;
let a_pillar = a_pillar_SBE;
let a_pillarwithcurtains = a_pillarwithcurtains_SBE;
let a_stalactite = a_stalactite_SBE;
let a_stalactitestalagmite = a_stalactitestalagmite_SBE;
let a_stalagmite = a_stalagmite_SBE;

let s_northarrow = s_northarrow_SKBB;
let s_scalebar = s_scalebar_SKBB;
let s_hgrid = s_hgrid_SM;
let s_vgrid = s_vgrid_SKBB;
let s_altitudebar = s_altitudebar_SKBB;



%%%%% ENDINPUT thTrans %%%%%



nonstopmode;
initsymbol("s_altitudebar_SKBB");
initsymbol("s_hgrid_SM");
initsymbol("s_northarrow_SKBB");
initsymbol("s_scalebar_SKBB");
initsymbol("s_scalebar_SM");
initsymbol("s_vgrid_SKBB");
initsymbol("s_vgrid_SM");
initsymbol("p_airdraught_AUT");
initsymbol("p_airdraught_UIS");
initsymbol("p_airdraught_summer_UIS");
initsymbol("p_airdraught_winter_UIS");
initsymbol("p_altar_SBE");
initsymbol("p_anastomosis_UIS");
initsymbol("p_anchor_SKBB");
initsymbol("p_aragonite_NSS");
initsymbol("p_archeoexcavation_SBE");
initsymbol("p_archeomaterial_UIS");
initsymbol("p_audio_SBE");
initsymbol("p_bat_SBE");
initsymbol("p_bedrock_ASF");
initsymbol("p_blocks_AUT");
initsymbol("p_blocks_UIS");
initsymbol("p_bones_SBE");
initsymbol("p_breakdownchoke_AUT");
initsymbol("p_breakdownchoke_NSS");
initsymbol("p_bridge_SKBB");
initsymbol("p_camp_SKBB");
initsymbol("p_cavepearl_SKBB");
initsymbol("p_clay_AUT");
initsymbol("p_clay_SKBB");
initsymbol("p_claychoke_AUT");
initsymbol("p_claytree_AUT");
initsymbol("p_continuation_UIS");
initsymbol("p_crystal_AUT");
initsymbol("p_crystal_UIS");
initsymbol("p_curtain_UIS");
initsymbol("p_curtains_UIS");
initsymbol("p_danger_SBE");
initsymbol("p_debris_AUT");
initsymbol("p_debris_UIS");
initsymbol("p_dig_UIS");
initsymbol("p_discpillar_UIS");
initsymbol("p_discpillars_UIS");
initsymbol("p_discstalactite_UIS");
initsymbol("p_discstalactites_UIS");
initsymbol("p_discstalagmite_UIS");
initsymbol("p_discstalagmites_UIS");
initsymbol("p_disk_UIS");
initsymbol("p_electriclight_SBE");
initsymbol("p_entrance_AUT");
initsymbol("p_entrance_UIS");
initsymbol("p_exvoto_SBE");
initsymbol("p_fixedladder_SKBB");
initsymbol("p_flowstone_UIS");
initsymbol("p_flowstonechoke_NSS");
initsymbol("p_flute_UIS");
initsymbol("p_gate_SBE");
initsymbol("p_gradient_AUT");
initsymbol("p_gradient_BCRA");
initsymbol("p_gradient_NSS");
initsymbol("p_gradient_SKBB");
initsymbol("p_gradient_UIS");
initsymbol("p_guano_UIS");
initsymbol("p_gypsum_NSS");
initsymbol("p_gypsumflower_NSS");
initsymbol("p_handrail_SKBB");
initsymbol("p_helictite_UIS");
initsymbol("p_helictites_UIS");
initsymbol("p_humanbones_SBE");
initsymbol("p_ice_AUT");
initsymbol("p_ice_UIS");
initsymbol("p_icepillar_AUT");
initsymbol("p_icestalactite_AUT");
initsymbol("p_icestalagmite_AUT");
initsymbol("p_karren_UIS");
initsymbol("p_lowend_NSS");
initsymbol("p_lowend_UIS");
initsymbol("p_masonry_SBE");
initsymbol("p_minus_UIS");
initsymbol("p_moonmilk_UIS");
initsymbol("p_mud_SBE");
initsymbol("p_mudcrack_SBE");
initsymbol("p_nameplate_SBE");
initsymbol("p_narrowend_UIS");
initsymbol("p_noequipment_SKBB");
initsymbol("p_nowheelchair_SBE");
initsymbol("p_paleomaterial_UIS");
initsymbol("p_pebbles_AUT");
initsymbol("p_pebbles_UIS");
initsymbol("p_pendant_SBE");
initsymbol("p_photo_SBE");
initsymbol("p_pillar_AUT");
initsymbol("p_pillar_UIS");
initsymbol("p_pillars_UIS");
initsymbol("p_pillarswithcurtains_UIS");
initsymbol("p_pillarwithcurtains_UIS");
initsymbol("p_plus_UIS");
initsymbol("p_plusminus_UIS");
initsymbol("p_popcorn_UIS");
initsymbol("p_raft_NSS");
initsymbol("p_raftcone_NSS");
initsymbol("p_rimstonedam_ASF");
initsymbol("p_rimstonepool_ASF");
initsymbol("p_root_ASF");
initsymbol("p_rope_SKBB");
initsymbol("p_ropeladder_SKBB");
initsymbol("p_sand_AUT");
initsymbol("p_sand_UIS");
initsymbol("p_scallop_UIS");
initsymbol("p_seedgermination_SBE");
initsymbol("p_sink_AUT");
initsymbol("p_sink_SKBB");
initsymbol("p_snow_SKBB");
initsymbol("p_sodastraw_UIS");
initsymbol("p_spring_AUT");
initsymbol("p_spring_SKBB");
initsymbol("p_stalactite_AUT");
initsymbol("p_stalactite_UIS");
initsymbol("p_stalactites_UIS");
initsymbol("p_stalactitesstalagmites_UIS");
initsymbol("p_stalactitestalagmite_UIS");
initsymbol("p_stalagmite_AUT");
initsymbol("p_stalagmite_UIS");
initsymbol("p_stalagmites_UIS");
initsymbol("p_station_SKBB");
initsymbol("p_station_fixed_ASF");
initsymbol("p_station_fixed_AUT");
initsymbol("p_station_natural_ASF");
initsymbol("p_station_painted_AUT");
initsymbol("p_station_painted_SKBB");
initsymbol("p_station_temporary_ASF");
initsymbol("p_station_temporary_AUT");
initsymbol("p_station_temporary_SKBB");
initsymbol("p_steps_SKBB");
initsymbol("p_traverse_SKBB");
initsymbol("p_treetrunk_SBE");
initsymbol("p_vegetabledebris_ASF");
initsymbol("p_viaferrata_SKBB");
initsymbol("p_volcano_SBE");
initsymbol("p_walkway_SBE");
initsymbol("p_wallcalcite_UIS");
initsymbol("p_water_AUT");
initsymbol("p_water_UIS");
initsymbol("p_waterdrip_SBE");
initsymbol("p_waterflow_intermittent_UIS");
initsymbol("p_waterflow_paleo_UIS");
initsymbol("p_waterflow_permanent_UIS");
initsymbol("p_wheelchair_SBE");
initsymbol("l_abyssentrance_SBE");
initsymbol("l_arrow_SKBB");
initsymbol("l_border_presumed_SKBB");
initsymbol("l_border_temporary_SKBB");
initsymbol("l_border_visible_SKBB");
initsymbol("l_ceilingmeander_AUT");
initsymbol("l_ceilingmeander_NZSS");
initsymbol("l_ceilingmeander_SKBB");
initsymbol("l_ceilingmeander_UIS");
initsymbol("l_ceilingstep_AUT");
initsymbol("l_ceilingstep_NZSS");
initsymbol("l_ceilingstep_SKBB");
initsymbol("l_ceilingstep_UIS");
initsymbol("l_chimney_NZSS");
initsymbol("l_chimney_UIS");
initsymbol("l_contour_AUT");
initsymbol("l_contour_SKBB");
initsymbol("l_contour_UIS");
initsymbol("l_dripline_SBE");
initsymbol("l_fault_SBE");
initsymbol("l_fixedladder_SKBB");
initsymbol("l_floormeander_SKBB");
initsymbol("l_floorstep_AUT");
initsymbol("l_floorstep_UIS");
initsymbol("l_flowstone_AUT");
initsymbol("l_flowstone_UIS");
initsymbol("l_gradient_BCRA");
initsymbol("l_gradient_UIS");
initsymbol("l_handrail_SKBB");
initsymbol("l_joint_SBE");
initsymbol("l_lowceiling_SBE");
initsymbol("l_mapconnection_SKBB");
initsymbol("l_moonmilk_UIS");
initsymbol("l_overhang_AUT");
initsymbol("l_overhang_SKBB");
initsymbol("l_pit_AUT");
initsymbol("l_pit_UIS");
initsymbol("l_pitchimney_SBE");
initsymbol("l_rimstonedam_SBE");
initsymbol("l_rimstonepool_SBE");
initsymbol("l_rockborder_UIS");
initsymbol("l_rockedge_UIS");
initsymbol("l_rope_SKBB");
initsymbol("l_ropeladder_SKBB");
initsymbol("l_section_SKBB");
initsymbol("l_slope_BCRA");
initsymbol("l_slope_SKBB");
initsymbol("l_steps_SKBB");
initsymbol("l_survey_cave_AUT");
initsymbol("l_survey_cave_SKBB");
initsymbol("l_survey_cave_UIS");
initsymbol("l_survey_surface_SKBB");
initsymbol("l_viaferrata_SKBB");
initsymbol("l_walkway_SBE");
initsymbol("l_wall_bedrock_UIS");
initsymbol("l_wall_blocks_AUT");
initsymbol("l_wall_blocks_SKBB");
initsymbol("l_wall_clay_AUT");
initsymbol("l_wall_clay_SKBB");
initsymbol("l_wall_debris_AUT");
initsymbol("l_wall_debris_SKBB");
initsymbol("l_wall_flowstone_AUT");
initsymbol("l_wall_ice_AUT");
initsymbol("l_wall_ice_SKBB");
initsymbol("l_wall_moonmilk_AUT");
initsymbol("l_wall_overlying_AUT");
initsymbol("l_wall_pebbles_AUT");
initsymbol("l_wall_pebbles_SKBB");
initsymbol("l_wall_pit_AUT");
initsymbol("l_wall_presumed_NZSS");
initsymbol("l_wall_presumed_UIS");
initsymbol("l_wall_sand_AUT");
initsymbol("l_wall_sand_SKBB");
initsymbol("l_wall_underlying_AUT");
initsymbol("l_wall_underlying_UIS");
initsymbol("l_wall_unsurveyed_SKBB");
initsymbol("l_waterflow_conjectural_SKBB");
initsymbol("l_waterflow_intermittent_SKBB");
initsymbol("l_waterflow_permanent_UIS");
initsymbol("a_bedrock_SKBB");
initsymbol("a_blocks_AUT");
initsymbol("a_blocks_SKBB");
initsymbol("a_clay_AUT");
initsymbol("a_clay_SKBB");
initsymbol("a_debris_AUT");
initsymbol("a_debris_SKBB");
initsymbol("a_debris_UIS");
initsymbol("a_dimensions_SKBB");
initsymbol("a_flowstone_ASF");
initsymbol("a_flowstone_AUT");
initsymbol("a_ice_AUT");
initsymbol("a_ice_SKBB");
initsymbol("a_moonmilk_SKBB");
initsymbol("a_mudcrack_SBE");
initsymbol("a_pebbles_AUT");
initsymbol("a_pebbles_SKBB");
initsymbol("a_pillar_SBE");
initsymbol("a_pillarwithcurtains_SBE");
initsymbol("a_sand_AUT");
initsymbol("a_sand_UIS");
initsymbol("a_snow_AUT");
initsymbol("a_snow_SKBB");
initsymbol("a_stalactite_SBE");
initsymbol("a_stalactitestalagmite_SBE");
initsymbol("a_stalagmite_SBE");
initsymbol("a_sump_AUT");
initsymbol("a_sump_SKBB");
initsymbol("a_sump_UIS");
initsymbol("a_water_AUT");
initsymbol("a_water_SKBB");
initsymbol("a_water_UIS");

background:=(0.00000,0.00000,0.10417,0.04000);
cmykcolor MapBackground; MapBackground := (0, 0, 0, 0.04);
lang:="fr";
ATTR__elevation:=false;

% user defined symbols defaults
% end of user defined symbols

defaultfont:="cmss10";
NorthDir:="true";
includeprefix := "/Users/martinkern/Documents/GitHub/Cavernicole/";
def s_scalebar (expr l, units, txt) =
begingroup
interim warningcheck:=0;
tmpl:=l / Scale * cm * units / 2;
tmpx:=l / Scale * cm * units / 5;
tmph:=3bp; % bar height
endgroup;
pickup PenC;
draw (-tmpl,0)--(tmpl,0)--(tmpl,-tmph)--(-tmpl,-tmph)--cycle;
p:=(0,0)--(tmpx,0)--(tmpx,-tmph)--(0,-tmph)--cycle;
for i:=-2.5 step 2 until 2:
fill p shifted (i * tmpx,0);
endfor;
begingroup
interim labeloffset:=3.5bp;
for i:=0 step (l/5) until (l-1):
tmpx:=tmpl * (i * 2 / l - 1);
label.bot(thTEX(decimal (i)),(tmpx,-tmph));
endfor;
label.bot(thTEX(decimal (l) & "\thinspace" & txt),(tmpl,-tmph));
% Pour écrire l'échelle "1:scale" au dessus de la barre décommenter la ligne suivante :
label.top(thTEX("Echelle 1 : " & decimal (Scale*100)),(0,0));
endgroup;
enddef;
def l_wall_presumed (expr P) =
T:=identity;
pickup PenA;
thdraw P dashed evenly scaled (.1u);
enddef;
def l_chimney (expr P) =
T:=identity;
pickup PenC;
%thdraw P dashed evenly scaled optical_zoom;
thdraw P dashed evenly scaled (.05u);
enddef;
def a_blocks (expr p) =
T:=identity;
pickup PenC;
path q, qq; q = bbox p;
picture tmp_pic;
uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
tmp_pic := image(
for i = xpart llcorner q step 0.75uu until xpart urcorner q:
for j = ypart llcorner q step 0.75uu until ypart urcorner q:
qq := punked (((-.3uu,-.3uu)--(.3uu,-.3uu)--(.3uu,.3uu)--(-.3uu,.3uu)--cycle)
randomized (uu/2))
rotated uniformdeviate(360)
shifted ((i,j) randomized 1.0uu);
if xpart (p intersectiontimes qq) < 0:
thclean qq;
thdraw qq;
fi;
endfor;
endfor;
);
clip tmp_pic to p;
draw tmp_pic;
enddef;
def a_sands (expr p) =
T:=identity;
pickup PenC;
path q; q = bbox p;
picture tmp_pic;
tmp_pic := image(
for i = xpart llcorner q step 0.1u until xpart urcorner q:
for j = ypart llcorner q step 0.1u until ypart urcorner q:
draw origin shifted ((i,j) randomized 0.1u) withpen PenC;
endfor;
endfor;
);
draw tmp_pic;
enddef;
def a_pebbles_SKBB (expr p) =
T:=identity;
pickup PenC;
path q, qq; q = bbox p;
picture tmp_pic;
tmp_pic := image(
for i = xpart llcorner q step .1u until xpart urcorner q:
for j = ypart llcorner q step .5u until ypart urcorner q:
qq := (superellipse((.07u,0),(0,.03u), (-.07u,0),(0,.-.03u),.75))
%randomized (u/25)
rotated uniformdeviate(360)
shifted ((i,j) randomized 0.27u);
if xpart (p intersectiontimes qq) < 0:
thdraw qq;
fi;
endfor;
endfor;
);
clip tmp_pic to p;
draw tmp_pic;
enddef;
def l_slope (expr P,S)(text Q) =
%show Q;
T:=identity;
numeric dirs[];
numeric lengths[];
for i=Q:
dirs[redpart i]:=greenpart i;
lengths[redpart i]:=bluepart i;
endfor;
li:=length(P); % last
alw_perpendicular:=true;
for i=0 upto li:
if unknown dirs[i]: dirs[i]:=-1;
else:
if dirs[i]>-1:
dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360;
alw_perpendicular:=false;
fi;
fi;
if unknown lengths[i]: lengths[i]:=-1; fi;
endfor;
%for i=0 upto li: show dirs[i]; endfor;
ni:=0; % next
pi:=0; % previous
for i=0 upto li:
d:=dirs[i];
if d=-1:
if (i=0) or (i=li):
dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
pi:=i;
else:
if ni<=i:
for j=i upto li:
ni:=j;
exitif dirs[j]>-1;
endfor;
fi;
w:=arclength(subpath(pi,i) of P) /
arclength(subpath(pi,ni) of P);
dirs[i]:=w[dirs[pi],dirs[ni]];
%if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%dirs[i]:=w[dirs[ni],dirs[pi]];
%message("*******");
%fi;
fi;
else:
pi:=i;
fi;
endfor;
%for i=0 upto li: show dirs[i]; endfor;
ni:=0; % next
pi:=0; % previous
for i=0 upto li:
l:=lengths[i];
if l=-1:
if (i=0) or (i=li):
lengths[i] := 1cm; % should never happen!
thwarning("slope width at the end point not specified");
pi:=i;
else:
if ni<=i:
for j=i+1 upto li:
ni:=j;
exitif lengths[j]>-1;
endfor;
fi;
w:=arclength(subpath(pi,i) of P) /
arclength(subpath(pi,ni) of P);
lengths[i]:=w[lengths[pi],lengths[ni]];
pi:=i;
fi;
else:
pi:=i;
fi;
endfor;
%for i=0 upto li: show lengths[i]; endfor;
T:=identity;
boolean par;
cas := 0.3u;
krok := 0.7u;
dlzka := (arclength P);
if dlzka>3u: dlzka:=dlzka-0.6u fi;
mojkrok:=adjust_step(dlzka,1.4u) / 5;
pickup PenD;
par := false;
forever:
t := arctime cas of P;
if t mod 1>0:  % not a key point
w := (arclength(subpath(floor t,t) of P) /
arclength(subpath(floor t,ceiling t) of P));
if alw_perpendicular:
a := 90;
else:
a := w[dirs[floor t],dirs[ceiling t]];
fi;
l := w[lengths[floor t],lengths[ceiling t]];
else:
if alw_perpendicular:
a := 90;
else:
a:= dirs[t];
fi;
l:=lengths[t];
fi;
a := a + angle(thdir(P,t));
thdraw (point t of P) --
((point t of P) + if par: 0.333 * fi l * unitvector(dir(a)));
cas := cas + mojkrok;
par := not par;
exitif cas > dlzka + .3u + (krok / 3);  % for rounding errors
endfor;
if S = 1: pickup PenC; draw P fi;
%pickup pencircle scaled 3pt;
%for i=0 upto li: draw point i of P; endfor;
enddef;
def a_snow (expr p) =
T:=identity;
thfill p withcolor (1.0, 1.0, 1.0);
enddef;
def a_water (expr p) =
T:=identity;
thfill p withcolor (0.17, 0.46, 1);
enddef;
def a_ice (expr p) =
T:=identity;
thfill p withcolor (0.7, 0.7, 0.9);
enddef;
def a_bedrock (expr p) =
T:=identity;
thfill p withcolor (0.90, 0.90, 0.90);
enddef;
def a_pebbles (expr p) =
T:=identity;
thfill p withcolor (0.6, 0.3, 0.0);
enddef;
def a_sump (expr p) =
T:=identity;
thfill p withcolor (0.06, 0.20, 0.65);
enddef;
def a_u_feuilles (expr p) =
T:=identity;
thfill p withcolor (0.0, 1.0, 0.0);
enddef;
def a_u_tronc (expr p) =
T:=identity;
thfill p withcolor (0.62, 0.24, 0.05);
enddef;
def a_u_guano (expr p) =
T:=identity;
thfill p withcolor (0.53, 0.26, 0.11);
enddef;
def a_sump (expr p) =
T:=identity;
thfill p withcolor (0.06, 0.20, 0.65);
enddef;
def s_northarrow (expr rot) =
begingroup
interim defaultscale:=0.7; % scale your north arrow here
T:=identity scaled defaultscale rotated -rot;
interim linecap:=squared;
interim linejoin:=rounded;
thfill (-.5cm,-.1cm)--(0,2.5cm)--(.5cm,-.1cm)--cycle;
pickup pencircle scaled (0.08cm * defaultscale);
thdraw (0,0)--(0,-2.5cm);
pickup pencircle scaled (0.16cm * defaultscale);
p:=(0.4cm,0.6cm);
thdraw ((p--(p yscaled -1)--(p xscaled -1)--(p scaled -1)) shifted (0,-1.0cm));
label.rt(thTEX("mg") scaled 1.6, (.6cm,-1.6cm)) transformed T;
endgroup;
enddef;
def p_altitude (expr pos) =
T:=identity shifted pos;
pickup PenD;
p:=(-.3u,0)--(.3u,0);
thdraw p; thdraw p rotated 90;
p:=fullcircle scaled .2u;
thclean p; thdraw p;
enddef;
vardef p_label@#(expr txt,pos,rot,mode) =
if mode=1:
thdrawoptions(withcolor .8red + .4blue);
p_altitude(pos);
% append "m" to label
picture txtm;
txtm:=image(
draw txt;
interim labeloffset:=0;
label.urt(btex \thaltitude { m} etex, lrcorner txt);
);
% give extra offset in case of l/r/t/b alignment
pair ctmp;
ctmp:=center thelabel@#("x", (0,0));
if (xpart ctmp * ypart ctmp)=0:
interim labeloffset:=(.4u);
else: % diagonal alignment
interim labeloffset:=(.2u);
fi;
% draw label
lab:=thelabel@#(txtm, pos);
draw lab _thop_; % use color
thdrawoptions();
bboxmargin:=0.8bp;
write_circ_bbox((bbox lab) smoothed 2);
else:
if mode=7: interim labeloffset:=(u/8) fi;
lab:=thelabel@#(txt, pos);
if mode>1: pickup PenD fi;
if mode=2: process_uplabel;
elseif mode=3: process_downlabel;
elseif mode=4: process_updownlabel;
elseif mode=5: process_circledlabel;
elseif mode=6: process_boxedlabel;
elseif mode=7: process_label(pos,rot);  % station name
elseif mode=8: process_filledlabel(pos, rot);
else: process_label(pos,rot); fi;
fi;
enddef;
verbatimtex \def\thheightpos{E}\def\thheightneg{P} etex
def l_u_strata (expr P) =
T:=identity;
path Q; Q = punked P;
for t = 0 upto length P - 1:
pair zz[];
zz1 := point t of P;
zz2 := point t+1 of P;
zz3 := postcontrol t of P;
zz4 := precontrol t+1 of P;
linecap:=0;
if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or (length(zz4-2/3[zz1,zz2]) > 0.1pt):
zz5 = whatever[zz1,zz2];
(zz3-zz5) = whatever * (zz1-zz2) rotated 90;
pickup pencircle scaled 1 mm;
draw zz1--zz5 dashed evenly;
pickup PenA;
draw zz1--zz5 withcolor background;
zz6 = whatever[zz1,zz2];
(zz4-zz6) = whatever * (zz1-zz2) rotated 90;
pickup pencircle scaled 1 mm;
draw zz2--zz6 dashed evenly;
pickup PenA;
draw zz2--zz6 withcolor background;
else:
pickup pencircle scaled 1 mm;
draw zz1--zz2 dashed evenly;
pickup PenA;
draw zz1--zz2 withcolor background;
fi;
endfor;
enddef;
def l_u_coupole (expr P) =
T:=identity;
cas := 0;                            % cursor to step along path
dlzka := arclength P;
mojkrok:=adjust_step(dlzka, 0.25u);  % symbol length nudged to be multiple of path length
q:= (0.10u,0.16u) -- (0.13u,0.17u);         % dot
pickup PenC;  %2nd thinnest pen
forever:
t := arctime cas of P;
thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % draw dots
cas := cas + mojkrok;
exitif cas > dlzka + (mojkrok / 3); % for rounding errors
endfor;
pickup PenC;   %2nd thickest pen
thdraw P;      %continuous line
enddef;
def l_u_fault (expr P) =
T:=identity;
path Q; Q = punked P;
pickup PenA;
for t = 0 upto length P - 1:
pair zz[];
zz1 := point t of P;
zz2 := point t+1 of P;
zz3 := postcontrol t of P;
zz4 := precontrol t+1 of P;
if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or (length(zz4-2/3[zz1,zz2]) > 0.1pt):
zz5 = whatever[zz1,zz2];
(zz3-zz5) = whatever * (zz1-zz2) rotated 90;
draw zz1--zz5 dashed evenly;
zz6 = whatever[zz1,zz2];
(zz4-zz6) = whatever * (zz1-zz2) rotated 90;
draw zz2--zz6 dashed evenly;
else:
draw zz1--zz2 dashed evenly;
fi;
endfor;
enddef;
def l_u_surf (expr P) =
T:=identity;
path Q; Q = punked P;
pickup PenC;
draw Q dashed evenly withcolor (0.5, 0, 0);
enddef;
def l_u_doline (expr P) =
T:=identity;
laenge:= arclength P;
symsize:=adjust_step(laenge,2u);
triangle_width:=symsize/10;
cur:=(symsize-triangle_width)/2;
pickup PenC;
forever:
t1 := arctime (cur) of P;
t  := arctime (cur + triangle_width/2) of P;
t2 := arctime (cur + triangle_width) of P;
thfill (subpath (t1,t2) of P) --
((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
cycle;
thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) --
(point t1 of P) withcolor (0.5, 0, 0);
cur := cur + symsize;
exitif cur > laenge - (1*symsize/3); % for rounding errors
t1:=arctime (cur) of P;
endfor;
enddef;
def p_gradient_XA (expr P,R,S,A) =
U:=(.15u, .4u);
T:=identity aligned A rotated R scaled S shifted P;
pickup PenC;
thdraw (0u, 0u) -- (0u, .4u);
thdraw (-.4u, 0u) -- (.4u, 0u);
enddef;
initsymbol ("p_gradient_XA");
path bat_path_x;
bat_path_x := (160.43589,619.76148)
.. controls (200.83034,598.56215) and (225.01974,599.82632) .. (242.33709,601.15842)
.. controls (250.91988,585.02142) and (280.12279,545.7622) .. (328.92385,566.52372)
.. controls (343.18917,529.89929) and (387.77695,513.04018) .. (453.54702,518.36185)
.. controls (456.6654,525.97557) and (466.09064,533.43257) .. (471.27843,523.05007)
.. controls (463.85291,520.67657) and (466.71891,517.42483) .. (471.63814,522.23522)
.. controls (472.87859,519.83044) and (472.11254,517.25674) .. (467.00984,516.24193)
.. controls (498.08181,494.38071) and (518.37927,488.7935) .. (554.08261,484.34703)
.. controls (536.23968,468.87122) and (526.7451,451.32142) .. (536.0878,433.78585)
.. controls (539.04313,428.23891) and (549.65293,437.81051) .. (550.08905,431.99134)
.. controls (543.35122,428.68782) and (547.16851,429.31755) .. (550.93619,430.90592)
.. controls (555.01514,419.20795) and (542.29889,420.82043) .. (539.21019,422.32967)
.. controls (526.80565,412.03922) and (538.14174,362.22955) .. (562.04206,325.41289)
.. controls (560.70416,305.4475) and (552.94665,275.48765) .. (596.42383,240.15823)
.. controls (586.13796,214.86512) and (584.21841,176.344) .. (618.88684,158.99293)
.. controls (600.38363,161.42082) and (571.90452,163.00167) .. (555.87287,173.29962)
.. controls (533.80922,180.31406) and (511.7587,189.77279) .. (494.76462,217.75852)
.. controls (469.02274,260.15007) and (465.60841,280.08537) .. (466.27659,287.73284)
.. controls (467.27295,299.13663) and (456.20597,295.4343) .. (455.42733,284.84646)
.. controls (447.034,297.47822) and (465.71846,292.96944) .. (457.40227,311.17742)
.. controls (451.51715,333.88534) and (454.55183,344.68208) .. (455.22274,365.27634)
.. controls (445.59186,380.66207) and (438.52169,394.98144) .. (432.56329,406.97544)
.. controls (421.27321,411.75599) and (411.86904,413.85884) .. (403.92838,423.33244)
.. controls (391.19793,418.79449) and (380.875,414.46152) .. (373.6673,409.41976)
.. controls (365.11095,413.84661) and (372.76761,437.1554) .. (372.88328,437.30963)
-- (360.72573,447.88215)
.. controls (360.72573,447.88215) and (348.36583,439.38367) .. (342.32921,440.26049)
.. controls (340.52016,451.25937) and (343.58923,463.9528) .. (354.67087,475.2679)
.. controls (341.63825,482.57642) and (339.10347,494.24676) .. (313.80723,490.57484)
.. controls (304.61922,489.24114) and (282.31298,490.61764) .. (258.32359,496.84657)
.. controls (246.18809,499.99759) and (248.48311,482.8706) .. (236.36849,493.22467)
.. controls (239.32461,491.85429) and (242.55704,492.01948) .. (245.59044,495.64662)
.. controls (248.83726,499.52895) and (249.4495,502.08244) .. (244.59097,503.87878)
.. controls (221.93401,514.80409) and (190.83965,541.85436) .. (178.69512,574.11392)
.. controls (176.80431,577.00681) and (162.4873,600.33708) .. cycle;
path bat_path_bb;
bat_path_bb = bbox bat_path_x;
path bat_path;
bat_path = bat_path_x shifted (-(llcorner bat_path_bb) - (urcorner bat_path_bb - llcorner bat_path_bb) / 2.0) scaled (1u / ((xpart urcorner bat_path_bb) - (xpart llcorner bat_path_bb))) rotated 210;
def p_u_bats(expr pos, theta, sc, al) =
T := identity shifted pos;
thfill (bat_path scaled 1.5) withcolor black;
enddef;
def l_u_bats(expr P) =
T:=identity;
cas := 0;
dlzka := arclength P;
mojkrok:=adjust_step(dlzka, 1.0u);
pickup PenD;
forever:
t := arctime cas of P;
thfill bat_path scaled 0.5 shifted (point t of P) withcolor black;
cas := cas + mojkrok;
exitif cas > dlzka + (mojkrok / 3); % for rounding errors
endfor;
enddef;
% bat pattern
beginpattern(pattern_bat);
fill bat_path withcolor black;
endpattern;
% bat area symbol
def a_u_bats (expr Path) =
T:=identity;
thclean Path;
thfill Path withpattern pattern_bat;
enddef;
def l_u_bats_legend =
l_u_bats(((.2,.2) -- (.8,.8)) inscale)
enddef;
def p_u_boss (expr pos,theta,sc,al)=
T:=identity aligned al rotated theta scaled sc shifted pos;
pickup PenD;
p := (0.08u,0.25u)..(0,0.29u)..(-0.08u,0.25u);
q := (0.16u,0.5u)..(0u,0.58u)..(-0.16u,0.5u);
for i=0 upto 9:
thdraw p rotated 36i withcolor (100, 0.6, 0.2);
thdraw q rotated 36i withcolor (100, 0.6, 0.2);
% black color
%thdraw p rotated 36i;
%thdraw q rotated 36i;
endfor
p := fullcircle scaled 0.15u;
thdraw p withcolor (100, 0.6, 0.2);
% black color
%thdraw p withcolor;
enddef;
def p_u_shell (expr pos,theta,sc,al)=
T:=identity shifted pos;
pickup PenB;
numeric turns, radius;
path ss, cesta;
pair za, zb;
turns = 1.55;
radius = .3u;
za = ( xpart(origin)+0, ypart(origin)+.1u ) rotated 370 turns;
zb = ( xpart(origin)+.3u, ypart(origin)+0 ) rotated 360 turns;
cesta := za--zb;
ss := (origin for t=1 upto 360 turns: -- dir t scaled t endfor) scaled (radius/turns/360);
thdraw ss withcolor (0.3);
thdraw (cesta cutbefore ss) withcolor (0.6);
enddef;
initsymbol ("p_u_shell");
def p_u_danger (expr P,R,S,A)=
T:=identity aligned A rotated R scaled S shifted P;
thfill (0,-u)--(u,0)--(0,u)--(0,.9u)--(.9u,0)--(0,-.9u)--cycle;
thfill (0,-u)--(-u,0)--(0,u)--(0,.9u)--(-.9u,0)--(0,-.9u)--cycle;
thfill (.1u,-.45u)..(0,-.35u)..(-.1u,-.45u)..(0,-.55u)..cycle;
thfill (0,-.2u)..(.1u,-.1u)--(.2u,.4u)..(0,.6u)..(-.2u,.4u)--(-.1u,-.1u)..cycle;
enddef;
def l_u_ariane (expr Path) =
T:=identity;
pickup PenD;
draw Path withcolor (100, 0, 0);
enddef;
def l_u_plankwalk  (expr P) = T:=identity;
cas := 0;
dlzka := arclength P;
mojrok := adjust_step(dlzka, 0.5u);
pickup PenD;
forever:
t := arctime cas of P;
thdraw ((point t of P) + 0.5 * u * unitvector(thdir(P,t) rotated 90)) --
((point t of P) - 0.5 * u * unitvector(thdir(P,t) rotated 90) );
cas := cas + mojrok;
exitif cas > dlzka + (mojrok/3);  % for rounding errors
endfor;
pickup PenC;
%thdraw P;
%draw path withcolor (0.5, 0 ,0)
enddef;
def l_u_rail (expr P) =
T:=identity;
cas := 0;
dlzka := arclength P;
mojkrok:=adjust_step(dlzka, 0.8u);
pickup PenC;
forever:
t0 := arctime (cas) of P;
t1 := arctime (cas + mojkrok*2/5) of P;
t  := arctime (cas + mojkrok/2) of P;
t4 := arctime (cas + mojkrok*3/5) of P;
t5 := arctime (cas + mojkrok) of P;
thdraw (subpath (t0,t1) of P);
thdraw (subpath (t4,t5) of P);
drawdot
(point t of P);
cas := cas + mojkrok;
exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
endfor;
enddef;
def l_flowstone (expr p) =
T:=identity;
cas := 0;
dlzka := arclength p;
mojkrok:=adjust_step(dlzka, .3u);
pickup PenC;
t1:=0;
forever:
t2 := arctime (cas + mojkrok) of p;
thdraw (point t1 of p){dir (angle(thdir(p,t1)) + 60)} ..
{dir (angle(thdir(p,t2)) - 60)}(point t2 of p);
cas := cas + mojkrok;
exitif cas > dlzka + (mojkrok / 3); % for rounding errors
t1:=t2;
endfor;
enddef;
def p_u_nid (expr pos,theta,sc,al)=
U:=(.4u,.2u);
T:=identity aligned al rotated theta scaled sc shifted pos;
pickup PenC;
thdraw (-.2u,.1u){dir -70}..{dir 70}(.2u,.1u) withcolor (0.53, 0.26, 0.11);
enddef;
def p_u_anchor_artificial(expr pos,theta,sc,al) =
T:=identity shifted pos;
thdraw origin withpen pencircle scaled 0.25u withcolor (0.58, 0.44, 0.25);
enddef;
initsymbol ("p_u_anchor_artificial");
def p_u_anchor_natural(expr pos,theta,sc,al) =
U:=(.2u,.2u);
T:=identity aligned al rotated theta scaled sc shifted pos;
thfill (-.2u,-.2u)--(0,.2u)--(.2u,-.2u)--cycle withcolor (0.58, 0.44, 0.25);
enddef;
initsymbol ("p_u_anchor_natural");
def l_u_deviation (expr P) =
begingroup;
save ellipse;
T:=identity;
pickup PenC;
path ellipse;
ellipse:=fullcircle xscaled (.5u) yscaled (.25u) shifted (point (length P) of P);
thdraw P cutafter ellipse;
draw ellipse;
endgroup;
enddef;
initsymbol("l_u_deviation");
def l_u_deviation_legend =
l_u_deviation(((.1,.5)--(.8,.5)) inscale);
enddef;
% store the original clean_legend_box
boolean l_rope_MY_inlegend;
l_rope_MY_inlegend:=false;
let l_rope_MY_legend_box = clean_legend_box;
% redefine clean_legend_box to store the flag, then run the original
def clean_legend_box =
l_rope_MY_inlegend:=true;
l_rope_MY_legend_box;
enddef;
def l_rope(expr P, show_anchors, show_rebelays)=
T:=identity;
pickup PenB;
if l_rope_MY_inlegend:
% drawing the legend - this gets run twice, since Therion draws two ropes, one for each parameter
if show_rebelays:
thdraw ((.35,.9) -- (.4,.85) -- (.4,.5) .. controls (.4,.4) and (.45,.4) .. (.5,.5) -- (.55,.45) -- (.55,.1)) inscale;
thdraw ((.4,.85) -- (.45,.9)) inscale;
thdraw ((.55,.45) -- (.6,.5)) inscale;
thfill fullcircle scaled .15u shifted ((.35,.9) inscale);
thfill fullcircle scaled .15u shifted ((.45,.9) inscale);
thfill fullcircle scaled .15u shifted ((.5,.5) inscale);
thfill fullcircle scaled .15u shifted ((.6,.5) inscale);
fi;
else:
begingroup;
save type;
string type;
if known ATTR_type:
type:=ATTR_type;
else:
type:="primary";
fi;
if type = "secondary":
thdraw P withcolor (0.7, 0.7, 0.7);
else:
thdraw P;
fi;
endgroup;
fi;
enddef;
% store the original clean_legend_box
boolean p_anchor_MY_inlegend;
p_anchor_MY_inlegend:=false;
let p_anchor_MY_legend_box = clean_legend_box;
% redefine clean_legend_box to store the flag, then run the original
def clean_legend_box =
p_anchor_MY_inlegend:=true;
p_anchor_MY_legend_box;
enddef;
% a P-hanger, fixed point or natural circle
def p_anchor_MY (expr P,R,S,A)=
if p_anchor_MY_inlegend:
% this is the legend - make sure the function works normally again
p_anchor_MY_inlegend:=false;
% draw a pretty legend - show all possibilities
string ATTR_type;
ATTR_type:="p";
p_anchor_MY((.2,.57) inscale,270,1,(0,0));
ATTR_type:="fixed";
p_anchor_MY((.5,.5) inscale,0,1,(0,0));
ATTR_type:="natural";
p_anchor_MY((.7,.5) inscale,0,1,(0,0));
else:
begingroup;
save type, facing;
T:=identity aligned A rotated R scaled S shifted P;
string type;
if known ATTR_type:
type:=ATTR_type;
else:
type:="auto";
fi;
if (type = "natural"):
U:=(.2u,.2u);
PenCThick:=(0.5u/10S); % thickness of PenC - pen thicknesses do not scale with S
% fill with background colour, to remove any rope lines going through the point
% this does not respect opacity, but there is no other way to remove lines from other objects
% clipping currentpicture does not work, since ropes are always drawn last, then layered beneath point symbols
thunfill fullcircle scaled (0.4u-PenCThick);
thdraw fullcircle scaled (0.4u-PenCThick) withpen PenC;
else:
if (type = "fixed") or (ATTR__elevation and (type = "auto")):
U:=(.2u,.2u);
thfill fullcircle scaled 0.4u;
else:
if (R > 0) and (R < 180):
facing:=-1
else:
facing:=1
fi;
if (type = "ropedp"):
T:=identity shifted (facing*-0.25u,-0.25u) aligned A rotated R scaled S shifted P;
fi;
U:=(.25u,.4u);
% thick part sticking out of the rock
thdraw (0,0)--(0,.4u) withpen PenB;
% thin part in the rock
thdraw (0,-.2u)--(0,0) withpen PenC;
% the loop should hang down the "page", based on the rotation
% stubs to hold the semicircle
thdraw (0,.1u)--(facing*.1u,.1u) withpen PenB;
thdraw (0,.4u)--(facing*.1u,.4u) withpen PenB;
% semicircle
thdraw halfcircle scaled .3u rotated (facing*-90) shifted (facing*.1u,.25u) withpen PenB;
fi;
fi;
endgroup;
fi;
enddef;
initsymbol("p_anchor_MY");
picture u_man_c_pic;
u_man_c_pic := image (
draw (0cm, -0cm) -- (-8cm, 27cm) -- (-36cm, 55cm) -- (-50cm, 99cm) withpen pencircle scaled 16cm;
draw (27cm, 48cm) -- (0, 64cm) -- (-29cm, 61cm) -- (-38cm, 102cm)  withpen pencircle scaled 16cm;
draw (-65cm, 48cm) -- (-75cm, 75cm) -- (-53cm, 106cm) -- (0, 106cm) withpen pencircle scaled 14cm;
draw (-44cm, 130cm) withpen pencircle scaled 27cm withcolor black;
) shifted (20cm, -67cm);
def p_u_man_c (expr P, R, S, A) =
U := (60cm, 85cm) scaled (0.01 / Scale);
T:=identity aligned A rotated R scaled S shifted P;
thdraw u_man_c_pic scaled (0.01 / Scale);
enddef;
initsymbol ("p_u_man_c");
def p_u_man_c_legend =
draw u_man_c_pic scaled (u / 175cm) shifted ((.5, .5) inscale);
enddef;
picture u_man_w_pic;
u_man_w_pic := image (
draw (0, 0) -- (7.5cm, 36cm) -- (0cm, 69cm) -- (9cm, 99cm) withpen pencircle scaled 16cm;
draw (42cm, 9cm) -- (37.5cm, 42cm) -- (13.5cm, 69cm) -- (30cm, 102cm) withpen pencircle scaled 16cm;
draw (21.5cm, 100.5cm) -- (6.6cm, 69cm) withpen pencircle scaled 16cm;
draw (-24cm, 75cm) -- (-13.5cm, 102cm) -- (9cm, 112.5cm) -- (30cm, 108cm) -- (51cm, 87cm) -- (75cm, 93cm) withpen pencircle scaled 14cm;
draw (30cm, 132cm) withpen pencircle scaled 27cm withcolor black;
) shifted (-20cm, -70cm);
def p_u_man_w (expr P, R, S, A) =
U := (60cm, 80cm) scaled (0.01 / Scale);
T:=identity aligned A rotated R scaled S shifted P;
thdraw u_man_w_pic scaled (0.01 / Scale);
enddef;
initsymbol ("p_u_man_w");
def p_u_man_w_legend =
draw u_man_w_pic scaled (u / 175cm) shifted ((.5, .5) inscale);
enddef;
def p_u_symbol_plan (expr pos,theta,sc,al) =
U := (-3.25u, 3.25u);
T := identity aligned al rotated theta scaled sc shifted pos;
pickup PenB;
q := ((-3.26u, -.95u) -- (1.74u, -.95u) -- (2.8u, .82u) -- (-1.49u, .82u) -- cycle);
thfill q withcolor .85;
thdraw q;
q := ((-.175u, .5u) -- (0u, 0u) -- (.175u, .5u) .. (0u, .45u) .. cycle);
thfill q withcolor .5green;
thdraw q withcolor .5green;
thdraw (0u, 0u) -- (0u, 2.31u) withcolor .5green;
enddef;
def p_u_symbol_extend (expr pos,theta,sc,al) =
U := (-2.5u, 2.5u);
T := identity aligned al rotated theta scaled sc shifted pos;
pickup PenB;
q := ((-2.346u, -2.480u) -- (-.48u, -2.116u) -- (-.48u, 1.573u) -- (-2.346u, 1.354u) -- cycle);
thfill q withcolor .85;
q := ((-1.551u, -2.878u) -- (1.438u, -.766u) -- (1.438u, 2.388u) -- (-1.551u, 1.118u) -- cycle);
thfill q withcolor .75;
thdraw q;
thdraw (-.48u, -2.116u) -- (-.48u, 1.573u) dashed evenly;
q := ((.446u, -1.461u) -- (2.120u, -1.094u) -- (2.120u, 2.184u) -- (.446u, 1.965u) -- cycle);
thfill q withcolor .85;
thdraw (.446u, -1.461u) -- (.446u, 1.965u) dashed evenly;
q := ((-.175u, .5u) -- (0u, 0u) -- (.175u, .5u) .. (0u, .45u) .. cycle) rotated -90;
thfill q withcolor .5green;
thdraw q withcolor .5green;
thdraw (0u, 0u) -- (2.31u, 0u) withcolor .5green;
enddef;
def a_u_galerie(expr P) =
T:=identity;
thfill P withcolor (0.82,0.75,0.48) withalpha 0.5;
enddef;
def l_wall_unsurveyed (expr P) =
T:=identity;
pickup PenC;
thdraw P dashed evenly scaled (0.5*optical_zoom);
enddef;
def l_survey_cave (expr P) =
% always draws full centreline, rather than short stubs like default cave centrelines
T:=identity;
pickup PenC;
if ATTR__shotflag_splay:
drawoptions(withcolor(0.5,0.5,0.5) withpen PenD);
thdraw P; %  grey & thin
drawoptions();
else: % not splay but may have either or both duplicate and approx flags set
if ATTR__shotflag_duplicate:
drawoptions(withcolor (1,1,0)); % differentiate duplicate with colour yellow
fi;
if ATTR__shotflag_approx:
thdraw P dashed evenly scaled optical_zoom;  % differentiate approx with dashed
else:
thdraw P;
fi;
thdrawoptions();
fi;
enddef;
mapsymbol("p_station_temporary","SKBB",true);
mapsymbol("p_pillar","AUT",true);
mapsymbol("p_anchor","MY",true);
mapsymbol("p_gradient","XA",true);
transparency:=true;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "alain-robert_sp5@Master";
ATTR__scrap := "alain-robert_sp5";
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "alain-robert_sp4@Master";
ATTR__scrap := "alain-robert_sp4";
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "alain-robert_sp3@Master";
ATTR__scrap := "alain-robert_sp3";
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "alain-robert_sp1@Master";
ATTR__scrap := "alain-robert_sp1";
beginfig(1);
ATTR__survey := "Master";
ATTR__height := -1;
drawoptions();
l_pit(((-45.26,-1.79)
 .. controls (-76.58,6.55) and (-77.02,-25.51) .. (-76.06,-28.08)
 .. controls (-75.10,-30.65) and (-60.55,-42.87) .. (-56.25,-35.87)
 .. controls (-51.95,-28.86) and (-43.08,-31.81) .. (-39.95,-34.12)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-41.38,49.57)
 .. controls (-41.38,49.57) and (-29.57,47.93) .. (-43.18,26.95)
 .. controls (-56.79,5.97) and (-62.08,0.81) .. (-62.23,-2.42)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((214.17,17.71) -- (134.37,-69.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((214.17,17.71) -- (228.73,54.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.03,49.96) -- (-93.60,-50.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.03,49.96) -- (-92.73,55.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-92.73,55.46) -- (-26.03,49.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-92.73,55.46) -- (-128.47,44.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-128.47,44.55) -- (-92.73,55.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-128.47,44.55) -- (-210.53,50.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-210.53,50.60) -- (-128.47,44.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-210.53,50.60) -- (-190.92,15.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-210.53,50.60) -- (-190.92,15.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-210.53,50.60) -- (-204.33,3.50)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-210.53,50.60) -- (-83.09,50.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-93.60,-50.90) -- (-90.64,-62.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-93.60,-50.90) -- (-26.03,49.96)));
endfig;
beginfig(2);
draw_upscrap(1)(1,((-210.85,40.31)
 .. controls (-210.85,40.31) and (-127.53,41.76) .. (-124.21,43.41)
 .. controls (-120.89,45.05) and (-97.36,47.18) .. (-93.76,47.01)
 .. controls (-90.17,46.84) and (-50.75,42.08) .. (-48.59,41.98)
 .. controls (-46.43,41.88) and (-54.53,23.16) .. (-63.07,17.80)
 .. controls (-66.32,15.76) and (-80.35,10.69) .. (-84.66,3.33)
 .. controls (-89.32,-4.61) and (-102.77,-43.34) .. (-96.73,-53.41)
 .. controls (-91.38,-62.31) and (-52.15,-63.45) .. (-49.43,-59.26)
 .. controls (-42.88,-49.16) and (-49.78,-36.17) .. (-45.36,-34.22)
 .. controls (-40.94,-32.27) and (-26.80,-30.42) .. (-24.66,-30.88)
),
1,((-24.66,-30.88)
 .. controls (-22.52,-31.34) and (7.79,-30.62) .. (7.79,-30.62)
),
1,((9.00,-5.08)
 .. controls (9.00,-5.08) and (-16.66,-6.75) .. (-24.23,-6.75)
),
1,((-24.23,-6.75)
 .. controls (-31.80,-6.75) and (-49.47,-6.99) .. (-51.82,-3.28)
 .. controls (-54.17,0.44) and (-13.78,46.46) .. (-20.63,53.99)
 .. controls (-27.48,61.52) and (-32.50,62.12) .. (-39.69,62.46)
 .. controls (-46.88,62.81) and (-90.21,68.83) .. (-97.26,64.48)
 .. controls (-104.32,60.13) and (-123.00,53.80) .. (-131.95,54.95)
 .. controls (-140.91,56.09) and (-211.47,57.64) .. (-211.47,57.64)
));
draw_downscrap;
endfig;
beginfig(3);
ATTR__id := "alain-robert_sp1_l3d";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-24.66,-30.88)
 .. controls (-22.52,-31.34) and (7.79,-30.62) .. (7.79,-30.62)
));
ATTR__id := "alain-robert_sp1_l1d";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-210.85,40.31)
 .. controls (-210.85,40.31) and (-127.53,41.76) .. (-124.21,43.41)
 .. controls (-120.89,45.05) and (-97.36,47.18) .. (-93.76,47.01)
 .. controls (-90.17,46.84) and (-50.75,42.08) .. (-48.59,41.98)
 .. controls (-46.43,41.88) and (-54.53,23.16) .. (-63.07,17.80)
 .. controls (-66.32,15.76) and (-80.35,10.69) .. (-84.66,3.33)
 .. controls (-89.32,-4.61) and (-102.77,-43.34) .. (-96.73,-53.41)
 .. controls (-91.38,-62.31) and (-52.15,-63.45) .. (-49.43,-59.26)
 .. controls (-42.88,-49.16) and (-49.78,-36.17) .. (-45.36,-34.22)
 .. controls (-40.94,-32.27) and (-26.80,-30.42) .. (-24.66,-30.88)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-58.33,11.45)
 .. controls (-58.33,11.45) and (-64.97,-6.98) .. (-61.92,-11.09)
 .. controls (-58.87,-15.20) and (-49.62,-17.80) .. (-48.22,-18.59)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-161.07,48.76)
 -- (-140.60,47.43)
));
ATTR__id := "alain-robert_sp1_l1g";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-24.23,-6.75)
 .. controls (-31.80,-6.75) and (-49.47,-6.99) .. (-51.82,-3.28)
 .. controls (-54.17,0.44) and (-13.78,46.46) .. (-20.63,53.99)
 .. controls (-27.48,61.52) and (-32.50,62.12) .. (-39.69,62.46)
 .. controls (-46.88,62.81) and (-90.21,68.83) .. (-97.26,64.48)
 .. controls (-104.32,60.13) and (-123.00,53.80) .. (-131.95,54.95)
 .. controls (-140.91,56.09) and (-211.47,57.64) .. (-211.47,57.64)
));
ATTR__id := "alain-robert_sp1_l3g";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((9.00,-5.08)
 .. controls (9.00,-5.08) and (-16.66,-6.75) .. (-24.23,-6.75)
));
ATTR__stationflag_splay := false;
ATTR__id := "";
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-93.60,-50.90),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-210.53,50.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-128.47,44.55),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-92.73,55.46),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-26.03,49.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((214.17,17.71),1,0,"");
endfig;
beginfig(4);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((-80.3496,10.6907),(-84.66,3.33),(-89.3152,-4.61262),btex \thwallaltitude \thfb\char45 \char49 \char51 \char57 \mainfont{} etex);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \mainfont{} etex, (-93.60, -50.90), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char48 \mainfont{} etex, (-210.53, 50.60), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \mainfont{} etex, (-128.47, 44.55), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \mainfont{} etex, (-92.73, 55.46), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char80 \char84 \char82 \char49 \mainfont{} etex, (-26.03, 49.96), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char48 \mainfont{} etex, (214.17, 17.71), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "100-130_sp1@Master";
ATTR__scrap := "100-130_sp1";
beginfig(5);
ATTR__height := -1;
drawoptions();
l_pit(((-168.10,98.87)
 .. controls (-168.10,98.87) and (-166.91,97.99) .. (-165.80,96.13)
 .. controls (-164.43,93.85) and (-166.80,92.25) .. (-165.68,90.34)
 .. controls (-164.66,88.61) and (-162.74,87.34) .. (-161.42,85.99)
 .. controls (-160.09,84.63) and (-158.97,85.13) .. (-156.84,84.43)
 .. controls (-154.97,83.83) and (-154.26,85.16) .. (-151.57,84.21)
 .. controls (-149.58,83.50) and (-148.79,83.85) .. (-147.65,85.80)
 .. controls (-146.08,88.47) and (-142.64,92.07) .. (-142.76,95.17)
 .. controls (-142.85,97.64) and (-144.35,98.41) .. (-146.71,99.66)
 .. controls (-148.16,100.43) and (-153.15,103.68) .. (-155.85,104.04)
 .. controls (-158.75,104.42) and (-159.85,105.41) .. (-163.01,105.69)
 .. controls (-165.99,105.96) and (-167.48,105.03) .. (-169.56,103.90)
 .. controls (-172.44,102.34) and (-168.10,98.87) .. cycle
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((183.37,-106.76) -- (205.83,-102.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((183.37,-106.76) -- (147.15,-65.08)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((147.15,-65.08) -- (183.37,-106.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((147.15,-65.08) -- (84.81,-66.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((84.81,-66.81) -- (147.15,-65.08)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((84.81,-66.81) -- (65.20,-31.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((84.81,-66.81) -- (65.20,-31.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((65.20,-31.51) -- (147.25,-37.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((65.20,-31.51) -- (84.81,-66.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((65.20,-31.51) -- (84.81,-66.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((65.20,-31.51) -- (71.40,-78.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((65.20,-31.51) -- (192.64,-31.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((71.40,-78.60) -- (65.20,-31.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((71.40,-78.60) -- (36.62,-62.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.62,-62.01) -- (71.40,-78.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((36.62,-62.01) -- (15.64,-57.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.64,-57.82) -- (36.62,-62.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.64,-57.82) -- (-50.73,-31.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-50.73,-31.94) -- (15.64,-57.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-50.73,-31.94) -- (-94.19,-15.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-94.19,-15.25) -- (-50.73,-31.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-94.19,-15.25) -- (-127.25,-1.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-127.25,-1.75) -- (-94.19,-15.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-127.25,-1.75) -- (-143.87,16.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-143.87,16.58) -- (-127.25,-1.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-143.87,16.58) -- (-163.83,25.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-143.87,16.58) -- (-128.44,1.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-163.83,25.31) -- (-143.87,16.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-163.83,25.31) -- (-179.47,54.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-179.47,54.61) -- (-163.83,25.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-179.47,54.61) -- (-189.87,96.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-189.87,96.09) -- (-179.47,54.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-189.87,96.09) -- (-166.50,84.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-166.50,84.95) -- (-189.87,96.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-166.50,84.95) -- (-144.07,96.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-144.07,96.89) -- (-166.50,84.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-144.07,96.89) -- (-149.32,100.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-149.32,100.13) -- (-144.07,96.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-149.32,100.13) -- (-169.00,106.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-169.00,106.80) -- (-149.32,100.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-169.00,106.80) -- (-174.68,114.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-203.55,96.05) -- (-198.94,101.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-174.68,114.22) -- (-169.00,106.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-174.68,114.22) -- (-191.41,109.12)));
endfig;
beginfig(6);
draw_upscrap(1)(1,((202.86,-115.23)
 .. controls (202.86,-115.23) and (182.38,-110.19) .. (177.50,-105.87)
 .. controls (172.62,-101.54) and (148.65,-77.85) .. (148.19,-77.07)
 .. controls (147.72,-76.30) and (128.46,-67.00) .. (109.00,-76.08)
 .. controls (89.83,-85.02) and (93.80,-75.04) .. (89.69,-73.44)
 .. controls (85.54,-71.83) and (87.61,-64.68) .. (74.93,-65.09)
 .. controls (71.02,-65.22) and (75.45,-75.46) .. (71.40,-78.60)
 .. controls (67.31,-81.76) and (39.99,-67.20) .. (37.64,-66.51)
 .. controls (35.29,-65.83) and (18.36,-59.17) .. (15.41,-58.46)
 .. controls (12.42,-57.73) and (-53.62,-35.83) .. (-57.85,-33.67)
 .. controls (-62.11,-31.50) and (-94.55,-17.90) .. (-98.32,-16.68)
 .. controls (-102.12,-15.45) and (-126.96,-2.91) .. (-128.34,-2.15)
 .. controls (-129.73,-1.39) and (-148.47,-4.86) .. (-150.94,-4.06)
 .. controls (-153.39,-3.26) and (-162.37,-0.55) .. (-166.95,3.21)
 .. controls (-171.53,6.97) and (-169.61,5.43) .. (-174.97,8.84)
 .. controls (-180.35,12.25) and (-192.98,19.17) .. (-196.62,20.03)
),
1,reverse ((-176.21,101.90)
 .. controls (-173.56,100.39) and (-174.99,102.50) .. (-171.02,99.48)
 .. controls (-166.04,95.67) and (-168.56,91.84) .. (-168.69,90.68)
 .. controls (-168.82,89.56) and (-180.27,94.13) .. (-182.02,94.72)
 .. controls (-183.71,95.28) and (-189.90,97.06) .. (-190.24,95.90)
 .. controls (-190.60,94.64) and (-194.42,83.51) .. (-194.54,80.73)
 .. controls (-194.67,77.91) and (-181.45,55.16) .. (-180.68,54.36)
 .. controls (-179.92,53.57) and (-168.23,27.74) .. (-168.26,23.77)
 .. controls (-168.29,19.78) and (-195.94,26.29) .. (-195.94,26.29)
),
1,reverse ((-138.88,80.18)
 .. controls (-141.79,84.46) and (-144.51,86.09) .. (-142.10,92.64)
 .. controls (-140.16,97.93) and (-144.10,100.05) .. (-147.86,103.30)
 .. controls (-150.27,105.38) and (-167.63,108.02) .. (-167.63,108.02)
),
1,reverse ((81.82,-28.36)
 .. controls (81.47,-28.24) and (73.89,-27.29) .. (64.48,-31.17)
 .. controls (55.02,-35.08) and (62.82,-48.29) .. (61.66,-54.27)
 .. controls (60.51,-60.20) and (64.37,-65.07) .. (62.69,-67.74)
 .. controls (60.97,-70.47) and (42.47,-60.97) .. (39.90,-59.57)
 .. controls (37.35,-58.17) and (18.94,-53.97) .. (16.57,-52.58)
 .. controls (14.19,-51.18) and (-41.21,-35.37) .. (-47.61,-32.17)
 .. controls (-54.05,-28.94) and (-86.25,-11.43) .. (-90.61,-9.34)
 .. controls (-95.01,-7.22) and (-110.63,-1.33) .. (-115.45,3.17)
 .. controls (-120.29,7.69) and (-135.73,19.60) .. (-139.74,22.83)
 .. controls (-143.81,26.11) and (-153.07,19.02) .. (-160.80,27.02)
 .. controls (-164.37,30.71) and (-161.97,40.05) .. (-176.78,60.49)
 .. controls (-191.98,81.47) and (-190.05,86.64) .. (-188.21,89.53)
 .. controls (-186.32,92.52) and (-166.90,84.21) .. (-166.90,84.21)
 .. controls (-166.90,84.21) and (-155.10,83.30) .. (-152.86,81.83)
 .. controls (-150.68,80.39) and (-150.22,81.56) .. (-147.03,77.16)
),
1,reverse ((196.44,-102.96)
 .. controls (195.61,-103.06) and (189.45,-102.66) .. (184.43,-102.35)
 .. controls (179.30,-102.02) and (168.58,-74.03) .. (168.24,-73.72)
 .. controls (167.91,-73.42) and (166.19,-69.53) .. (161.44,-65.02)
 .. controls (156.71,-60.53) and (150.21,-63.06) .. (146.86,-63.48)
 .. controls (143.53,-63.90) and (104.43,-63.73) .. (94.71,-61.68)
 .. controls (84.93,-59.62) and (90.79,-55.46) .. (81.29,-51.26)
 .. controls (63.38,-43.34) and (82.17,-36.77) .. (82.17,-36.77)
));
draw_downscrap;
endfig;
beginfig(7);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((202.86,-115.23)
 .. controls (202.86,-115.23) and (182.38,-110.19) .. (177.50,-105.87)
 .. controls (172.62,-101.54) and (148.65,-77.85) .. (148.19,-77.07)
 .. controls (147.72,-76.30) and (128.46,-67.00) .. (109.00,-76.08)
 .. controls (89.83,-85.02) and (93.80,-75.04) .. (89.69,-73.44)
 .. controls (85.54,-71.83) and (87.61,-64.68) .. (74.93,-65.09)
 .. controls (71.02,-65.22) and (75.45,-75.46) .. (71.40,-78.60)
 .. controls (67.31,-81.76) and (39.99,-67.20) .. (37.64,-66.51)
 .. controls (35.29,-65.83) and (18.36,-59.17) .. (15.41,-58.46)
 .. controls (12.42,-57.73) and (-53.62,-35.83) .. (-57.85,-33.67)
 .. controls (-62.11,-31.50) and (-94.55,-17.90) .. (-98.32,-16.68)
 .. controls (-102.12,-15.45) and (-126.96,-2.91) .. (-128.34,-2.15)
 .. controls (-129.73,-1.39) and (-148.47,-4.86) .. (-150.94,-4.06)
 .. controls (-153.39,-3.26) and (-162.37,-0.55) .. (-166.95,3.21)
 .. controls (-171.53,6.97) and (-169.61,5.43) .. (-174.97,8.84)
 .. controls (-180.35,12.25) and (-192.98,19.17) .. (-196.62,20.03)
));
ATTR__id := "l10_cav_100-130";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-176.21,101.90)
 .. controls (-173.56,100.39) and (-174.99,102.50) .. (-171.02,99.48)
 .. controls (-166.04,95.67) and (-168.56,91.84) .. (-168.69,90.68)
 .. controls (-168.82,89.56) and (-180.27,94.13) .. (-182.02,94.72)
 .. controls (-183.71,95.28) and (-189.90,97.06) .. (-190.24,95.90)
 .. controls (-190.60,94.64) and (-194.42,83.51) .. (-194.54,80.73)
 .. controls (-194.67,77.91) and (-181.45,55.16) .. (-180.68,54.36)
 .. controls (-179.92,53.57) and (-168.23,27.74) .. (-168.26,23.77)
 .. controls (-168.29,19.78) and (-195.94,26.29) .. (-195.94,26.29)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((196.44,-102.96)
 .. controls (195.61,-103.06) and (189.45,-102.66) .. (184.43,-102.35)
 .. controls (179.30,-102.02) and (168.58,-74.03) .. (168.24,-73.72)
 .. controls (167.91,-73.42) and (166.19,-69.53) .. (161.44,-65.02)
 .. controls (156.71,-60.53) and (150.21,-63.06) .. (146.86,-63.48)
 .. controls (143.53,-63.90) and (104.43,-63.73) .. (94.71,-61.68)
 .. controls (84.93,-59.62) and (90.79,-55.46) .. (81.29,-51.26)
 .. controls (63.38,-43.34) and (82.17,-36.77) .. (82.17,-36.77)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((81.82,-28.36)
 .. controls (81.47,-28.24) and (73.89,-27.29) .. (64.48,-31.17)
 .. controls (55.02,-35.08) and (62.82,-48.29) .. (61.66,-54.27)
 .. controls (60.51,-60.20) and (64.37,-65.07) .. (62.69,-67.74)
 .. controls (60.97,-70.47) and (42.47,-60.97) .. (39.90,-59.57)
 .. controls (37.35,-58.17) and (18.94,-53.97) .. (16.57,-52.58)
 .. controls (14.19,-51.18) and (-41.21,-35.37) .. (-47.61,-32.17)
 .. controls (-54.05,-28.94) and (-86.25,-11.43) .. (-90.61,-9.34)
 .. controls (-95.01,-7.22) and (-110.63,-1.33) .. (-115.45,3.17)
 .. controls (-120.29,7.69) and (-135.73,19.60) .. (-139.74,22.83)
 .. controls (-143.81,26.11) and (-153.07,19.02) .. (-160.80,27.02)
 .. controls (-164.37,30.71) and (-161.97,40.05) .. (-176.78,60.49)
 .. controls (-191.98,81.47) and (-190.05,86.64) .. (-188.21,89.53)
 .. controls (-186.32,92.52) and (-166.90,84.21) .. (-166.90,84.21)
 .. controls (-166.90,84.21) and (-155.10,83.30) .. (-152.86,81.83)
 .. controls (-150.68,80.39) and (-150.22,81.56) .. (-147.03,77.16)
));
ATTR__id := "l11_cav_100-130";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-138.88,80.18)
 .. controls (-141.79,84.46) and (-144.51,86.09) .. (-142.10,92.64)
 .. controls (-140.16,97.93) and (-144.10,100.05) .. (-147.86,103.30)
 .. controls (-150.27,105.38) and (-167.63,108.02) .. (-167.63,108.02)
));
ATTR__stationflag_splay := false;
ATTR__id := "";
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-174.68,114.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-203.55,96.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-169.00,106.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-149.32,100.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-144.07,96.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-166.50,84.95),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-189.87,96.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-179.47,54.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-163.83,25.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-143.87,16.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-127.25,-1.75),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-94.19,-15.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-50.73,-31.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((15.64,-57.82),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((36.62,-62.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((71.40,-78.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((65.20,-31.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((84.81,-66.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((147.15,-65.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((183.37,-106.76),1,0,"");
endfig;
beginfig(8);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \mainfont{} etex, (-174.68, 114.22), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char53 \mainfont{} etex, (-203.55, 96.05), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \mainfont{} etex, (-169.00, 106.80), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \mainfont{} etex, (-149.32, 100.13), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \mainfont{} etex, (-144.07, 96.89), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \mainfont{} etex, (-166.50, 84.95), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \mainfont{} etex, (-189.87, 96.09), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \mainfont{} etex, (-179.47, 54.61), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \mainfont{} etex, (-163.83, 25.31), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char57 \mainfont{} etex, (-143.87, 16.58), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \mainfont{} etex, (-127.25, -1.75), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \mainfont{} etex, (-94.19, -15.25), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char50 \mainfont{} etex, (-50.73, -31.94), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char51 \mainfont{} etex, (15.64, -57.82), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char52 \mainfont{} etex, (36.62, -62.01), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char53 \mainfont{} etex, (71.40, -78.60), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char54 \mainfont{} etex, (65.20, -31.51), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char56 \mainfont{} etex, (84.81, -66.81), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char57 \mainfont{} etex, (147.15, -65.08), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char48 \mainfont{} etex, (183.37, -106.76), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "100-130_sp2@Master";
ATTR__scrap := "100-130_sp2";
beginfig(9);
ATTR__height := -1;
drawoptions();
l_pit(((181.08,-86.33)
 .. controls (181.08,-86.33) and (180.76,-89.14) .. (180.30,-90.48)
 .. controls (179.84,-91.81) and (178.01,-93.21) .. (178.18,-95.02)
 .. controls (178.34,-96.84) and (181.97,-102.12) .. (182.49,-102.43)
 .. controls (183.01,-102.75) and (187.95,-104.96) .. (189.27,-105.61)
 .. controls (190.58,-106.26) and (192.94,-107.53) .. (195.78,-109.67)
 .. controls (198.61,-111.80) and (200.87,-108.59) .. (207.90,-110.49)
 .. controls (214.92,-112.39) and (212.22,-113.28) .. (217.88,-110.52)
 .. controls (218.76,-110.09) and (218.50,-109.56) .. (220.69,-107.08)
 .. controls (222.88,-104.61) and (223.16,-104.44) .. (223.65,-102.84)
 .. controls (224.13,-101.23) and (222.23,-98.99) .. (221.07,-96.35)
 .. controls (219.92,-93.70) and (220.35,-92.73) .. (219.43,-90.56)
 .. controls (218.50,-88.39) and (217.29,-86.38) .. (215.36,-84.41)
 .. controls (213.42,-82.43) and (210.00,-82.49) .. (207.95,-81.47)
 .. controls (205.14,-80.06) and (201.72,-82.08) .. (198.48,-81.57)
 .. controls (195.23,-81.05) and (192.96,-82.15) .. (188.94,-82.04)
 .. controls (184.92,-81.92) and (184.22,-82.70) .. (182.69,-83.41)
 .. controls (181.16,-84.13) and (181.08,-86.33) .. cycle
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-228.49,114.60) -- (-233.09,109.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-228.49,114.60) -- (-150.45,67.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-150.45,67.33) -- (-228.49,114.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-150.45,67.33) -- (-83.95,19.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-83.95,19.53) -- (-150.45,67.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-83.95,19.53) -- (-47.56,-0.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.56,-0.72) -- (-83.95,19.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-47.56,-0.72) -- (25.10,-34.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((25.10,-34.77) -- (-47.56,-0.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((25.10,-34.77) -- (-5.99,2.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-5.99,2.82) -- (25.10,-34.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-5.99,2.82) -- (-23.03,21.16)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-23.03,21.16) -- (-5.99,2.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-23.03,21.16) -- (17.55,11.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.55,11.56) -- (-23.03,21.16)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.55,11.56) -- (29.11,-5.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((29.11,-5.32) -- (17.55,11.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((29.11,-5.32) -- (81.95,-33.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((81.95,-33.66) -- (29.11,-5.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((81.95,-33.66) -- (73.61,-49.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((73.61,-49.04) -- (81.95,-33.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((73.61,-49.04) -- (117.00,-53.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((176.29,-88.78) -- (144.35,-86.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((176.29,-88.78) -- (153.83,-93.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((144.35,-86.21) -- (117.00,-53.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((144.35,-86.21) -- (176.29,-88.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((117.00,-53.37) -- (73.61,-49.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((117.00,-53.37) -- (144.35,-86.21)));
endfig;
beginfig(10);
draw_upscrap(1)(1,((11.94,-21.64)
 .. controls (20.69,-29.55) and (18.56,-29.00) .. (14.98,-26.95)
 .. controls (12.20,-25.36) and (-41.18,0.71) .. (-43.60,1.06)
 .. controls (-46.02,1.41) and (-79.43,25.77) .. (-81.34,26.82)
 .. controls (-83.25,27.86) and (-144.13,68.17) .. (-146.57,69.94)
 .. controls (-148.99,71.70) and (-168.43,93.55) .. (-168.43,93.55)
),
1,((-176.57,90.52)
 .. controls (-176.57,90.52) and (-157.57,70.06) .. (-154.11,66.86)
 .. controls (-150.66,63.68) and (-93.55,23.89) .. (-87.68,19.46)
 .. controls (-81.79,15.00) and (-53.46,-1.04) .. (-48.80,-4.36)
 .. controls (-44.15,-7.67) and (-22.80,-23.13) .. (-17.39,-25.78)
 .. controls (-11.98,-28.43) and (17.98,-35.48) .. (22.81,-38.11)
 .. controls (27.66,-40.76) and (26.17,-38.07) .. (32.00,-36.51)
 .. controls (37.98,-34.92) and (15.89,-16.31) .. (14.20,-13.24)
 .. controls (12.51,-10.17) and (0.08,-1.44) .. (-2.61,1.71)
 .. controls (-5.31,4.86) and (-12.19,12.89) .. (-14.90,16.29)
 .. controls (-18.08,20.27) and (3.37,12.58) .. (7.04,11.84)
 .. controls (10.71,11.11) and (16.43,10.24) .. (14.06,6.69)
 .. controls (11.87,3.42) and (14.00,-1.03) .. (14.00,-1.03)
),
1,((14.00,-1.03)
 .. controls (20.15,-9.15) and (24.13,-9.69) .. (31.30,-13.01)
 .. controls (38.49,-16.34) and (40.48,-14.13) .. (47.32,-18.44)
 .. controls (54.17,-22.75) and (56.91,-23.42) .. (60.48,-27.94)
 .. controls (64.06,-32.46) and (59.55,-34.08) .. (58.28,-37.99)
 .. controls (57.01,-41.87) and (69.07,-46.91) .. (71.46,-49.23)
 .. controls (73.86,-51.55) and (93.68,-53.31) .. (102.99,-54.46)
 .. controls (112.30,-55.61) and (116.62,-58.86) .. (118.91,-60.72)
 .. controls (121.20,-62.58) and (141.54,-84.31) .. (144.35,-86.21)
 .. controls (147.23,-88.16) and (156.43,-88.05) .. (156.43,-88.05)
 .. controls (156.43,-88.05) and (171.65,-87.41) .. (173.40,-88.76)
 .. controls (175.17,-90.13) and (166.89,-89.60) .. (166.89,-89.60)
),
1,((173.31,-101.87)
 .. controls (173.31,-101.87) and (174.50,-103.06) .. (176.45,-103.86)
 .. controls (178.40,-104.65) and (178.91,-103.97) .. (182.75,-105.01)
 .. controls (186.59,-106.05) and (184.64,-106.44) .. (190.84,-109.84)
 .. controls (197.04,-113.23) and (201.62,-111.75) .. (211.60,-113.05)
 .. controls (221.56,-114.35) and (218.09,-111.27) .. (223.51,-106.84)
 .. controls (228.93,-102.43) and (223.66,-100.47) .. (221.33,-90.53)
 .. controls (219.00,-80.58) and (215.31,-83.77) .. (210.11,-80.54)
 .. controls (204.89,-77.30) and (196.44,-81.96) .. (185.62,-80.05)
 .. controls (181.82,-79.38) and (179.17,-83.80) .. (179.17,-83.80)
),
1,reverse ((11.94,-21.64)
 .. controls (11.94,-21.64) and (-3.00,-5.31) .. (-4.32,-4.01)
 .. controls (-5.65,-2.71) and (-10.25,0.52) .. (-12.64,3.02)
 .. controls (-15.04,5.52) and (-28.61,19.81) .. (-29.21,21.32)
 .. controls (-29.81,22.82) and (-33.70,34.27) .. (-20.77,28.71)
 .. controls (-7.88,23.17) and (-5.81,20.10) .. (-0.36,19.96)
 .. controls (5.09,19.82) and (17.10,13.97) .. (19.61,11.18)
 .. controls (22.10,8.41) and (30.56,-3.27) .. (32.09,-4.74)
 .. controls (33.62,-6.21) and (83.54,-31.82) .. (83.33,-34.29)
 .. controls (83.13,-36.71) and (80.93,-43.63) .. (81.66,-43.74)
 .. controls (82.40,-43.85) and (113.92,-50.87) .. (117.27,-52.43)
 .. controls (128.05,-57.45) and (135.79,-71.40) .. (146.69,-80.68)
 .. controls (149.90,-83.41) and (177.17,-86.78) .. (179.17,-83.80)
));
draw_downscrap;
endfig;
beginfig(11);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.94,-21.64)
 .. controls (20.69,-29.55) and (18.56,-29.00) .. (14.98,-26.95)
 .. controls (12.20,-25.36) and (-41.18,0.71) .. (-43.60,1.06)
 .. controls (-46.02,1.41) and (-79.43,25.77) .. (-81.34,26.82)
 .. controls (-83.25,27.86) and (-144.13,68.17) .. (-146.57,69.94)
 .. controls (-148.99,71.70) and (-168.43,93.55) .. (-168.43,93.55)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.94,-21.64)
 .. controls (11.94,-21.64) and (-3.00,-5.31) .. (-4.32,-4.01)
 .. controls (-5.65,-2.71) and (-10.25,0.52) .. (-12.64,3.02)
 .. controls (-15.04,5.52) and (-28.61,19.81) .. (-29.21,21.32)
 .. controls (-29.81,22.82) and (-33.70,34.27) .. (-20.77,28.71)
 .. controls (-7.88,23.17) and (-5.81,20.10) .. (-0.36,19.96)
 .. controls (5.09,19.82) and (17.10,13.97) .. (19.61,11.18)
 .. controls (22.10,8.41) and (30.56,-3.27) .. (32.09,-4.74)
 .. controls (33.62,-6.21) and (83.54,-31.82) .. (83.33,-34.29)
 .. controls (83.13,-36.71) and (80.93,-43.63) .. (81.66,-43.74)
 .. controls (82.40,-43.85) and (113.92,-50.87) .. (117.27,-52.43)
 .. controls (128.05,-57.45) and (135.79,-71.40) .. (146.69,-80.68)
 .. controls (149.90,-83.41) and (177.17,-86.78) .. (179.17,-83.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((173.31,-101.87)
 .. controls (173.31,-101.87) and (174.50,-103.06) .. (176.45,-103.86)
 .. controls (178.40,-104.65) and (178.91,-103.97) .. (182.75,-105.01)
 .. controls (186.59,-106.05) and (184.64,-106.44) .. (190.84,-109.84)
 .. controls (197.04,-113.23) and (201.62,-111.75) .. (211.60,-113.05)
 .. controls (221.56,-114.35) and (218.09,-111.27) .. (223.51,-106.84)
 .. controls (228.93,-102.43) and (223.66,-100.47) .. (221.33,-90.53)
 .. controls (219.00,-80.58) and (215.31,-83.77) .. (210.11,-80.54)
 .. controls (204.89,-77.30) and (196.44,-81.96) .. (185.62,-80.05)
 .. controls (181.82,-79.38) and (179.17,-83.80) .. (179.17,-83.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((14.00,-1.03)
 .. controls (20.15,-9.15) and (24.13,-9.69) .. (31.30,-13.01)
 .. controls (38.49,-16.34) and (40.48,-14.13) .. (47.32,-18.44)
 .. controls (54.17,-22.75) and (56.91,-23.42) .. (60.48,-27.94)
 .. controls (64.06,-32.46) and (59.55,-34.08) .. (58.28,-37.99)
 .. controls (57.01,-41.87) and (69.07,-46.91) .. (71.46,-49.23)
 .. controls (73.86,-51.55) and (93.68,-53.31) .. (102.99,-54.46)
 .. controls (112.30,-55.61) and (116.62,-58.86) .. (118.91,-60.72)
 .. controls (121.20,-62.58) and (141.54,-84.31) .. (144.35,-86.21)
 .. controls (147.23,-88.16) and (156.43,-88.05) .. (156.43,-88.05)
 .. controls (156.43,-88.05) and (171.65,-87.41) .. (173.40,-88.76)
 .. controls (175.17,-90.13) and (166.89,-89.60) .. (166.89,-89.60)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-176.57,90.52)
 .. controls (-176.57,90.52) and (-157.57,70.06) .. (-154.11,66.86)
 .. controls (-150.66,63.68) and (-93.55,23.89) .. (-87.68,19.46)
 .. controls (-81.79,15.00) and (-53.46,-1.04) .. (-48.80,-4.36)
 .. controls (-44.15,-7.67) and (-22.80,-23.13) .. (-17.39,-25.78)
 .. controls (-11.98,-28.43) and (17.98,-35.48) .. (22.81,-38.11)
 .. controls (27.66,-40.76) and (26.17,-38.07) .. (32.00,-36.51)
 .. controls (37.98,-34.92) and (15.89,-16.31) .. (14.20,-13.24)
 .. controls (12.51,-10.17) and (0.08,-1.44) .. (-2.61,1.71)
 .. controls (-5.31,4.86) and (-12.19,12.89) .. (-14.90,16.29)
 .. controls (-18.08,20.27) and (3.37,12.58) .. (7.04,11.84)
 .. controls (10.71,11.11) and (16.43,10.24) .. (14.06,6.69)
 .. controls (11.87,3.42) and (14.00,-1.03) .. (14.00,-1.03)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((117.00,-53.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((144.35,-86.21),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((176.29,-88.78),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((73.61,-49.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((81.95,-33.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((29.11,-5.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((17.55,11.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-23.03,21.16),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-5.99,2.82),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((25.10,-34.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-47.56,-0.72),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-83.95,19.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-150.45,67.33),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-228.49,114.60),1,0,"");
endfig;
beginfig(12);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char51 \mainfont{} etex, (117.00, -53.37), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char50 \mainfont{} etex, (144.35, -86.21), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char49 \mainfont{} etex, (176.29, -88.78), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char52 \mainfont{} etex, (73.61, -49.04), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char53 \mainfont{} etex, (81.95, -33.66), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char54 \mainfont{} etex, (29.11, -5.32), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char55 \mainfont{} etex, (17.55, 11.56), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char56 \mainfont{} etex, (-23.03, 21.16), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char57 \mainfont{} etex, (-5.99, 2.82), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char48 \mainfont{} etex, (25.10, -34.77), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char49 \mainfont{} etex, (-47.56, -0.72), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char50 \mainfont{} etex, (-83.95, 19.53), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char51 \mainfont{} etex, (-150.45, 67.33), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char52 \mainfont{} etex, (-228.49, 114.60), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "alain-robert_sp2@Master";
ATTR__scrap := "alain-robert_sp2";
beginfig(13);
current_src := "datas/alain-robert/datas/alain-robert/alain-robert_p.th2 [151]";
string area_border[];
area_border[1] := "l54-664-426";
drawoptions();
a_water(buildcycle(((-101.77,-84.00)
 .. controls (-101.77,-84.00) and (-104.41,-101.54) .. (-99.06,-102.87)
 .. controls (-93.72,-104.20) and (-74.89,-94.65) .. (-74.89,-94.65)
 .. controls (-74.89,-94.65) and (-84.00,-81.60) .. (-87.87,-79.61)
 .. controls (-91.74,-77.63) and (-101.77,-84.00) .. cycle
)));
current_src := "datas/alain-robert/datas/alain-robert/alain-robert_p.th2 [113]";
string area_border[];
area_border[1] := "l71-797-566";
drawoptions();
a_water(buildcycle(((-18.34,-11.92)
 .. controls (-18.34,-11.92) and (-12.64,-20.84) .. (-8.99,-19.93)
 .. controls (-5.34,-19.02) and (13.21,-15.21) .. (15.95,-10.66)
 .. controls (19.37,-4.97) and (27.22,6.47) .. (24.43,8.40)
 .. controls (21.64,10.34) and (-6.41,11.67) .. (-6.41,11.67)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((-201.06,-87.58)
 .. controls (-201.35,-86.12) and (-200.43,-59.14) .. (-198.15,-56.72)
 .. controls (-195.87,-54.31) and (-185.77,-54.07) .. (-185.19,-49.41)
 .. controls (-184.61,-44.75) and (-177.72,-40.03) .. (-177.31,-35.37)
 .. controls (-176.38,-24.55) and (-186.00,-13.33) .. (-182.69,-4.47)
 .. controls (-179.39,4.38) and (-207.39,14.36) .. (-215.81,11.52)
 .. controls (-224.24,8.68) and (-222.66,-3.65) .. (-224.67,-7.88)
 .. controls (-226.67,-12.11) and (-208.86,-16.57) .. (-223.96,-30.99)
 .. controls (-228.28,-35.11) and (-206.22,-52.01) .. (-205.34,-56.38)
 .. controls (-204.47,-60.75) and (-210.90,-97.56) .. (-210.00,-101.21)
));
ATTR__height := -1;
drawoptions();
l_pit(((57.32,-12.26)
 .. controls (42.63,-10.48) and (34.53,8.64) .. (34.53,8.64)
));
ATTR__height := -1;
drawoptions();
l_pit(((154.22,77.56)
 .. controls (154.22,77.56) and (149.83,91.46) .. (146.16,90.20)
 .. controls (142.50,88.93) and (103.56,65.91) .. (102.71,63.07)
 .. controls (101.85,60.23) and (89.06,48.94) .. (83.22,47.42)
 .. controls (77.39,45.89) and (51.19,17.94) .. (50.71,15.44)
 .. controls (50.23,12.94) and (39.93,0.82) .. (40.58,-0.65)
));
ATTR__height := -1;
drawoptions();
l_pit(((155.78,118.21)
 .. controls (157.94,110.54) and (139.17,102.42) .. (139.17,102.42)
));
ATTR__height := -1;
drawoptions();
l_chimney(((-132.77,-91.54)
 .. controls (-134.63,-92.89) and (-136.50,-98.03) .. (-133.99,-98.33)
 .. controls (-131.48,-98.63) and (-126.18,-97.08) .. (-126.95,-94.34)
 .. controls (-127.72,-91.60) and (-130.90,-90.19) .. cycle
));
ATTR__height := -1;
drawoptions();
l_chimney(((-126.67,-107.33)
 .. controls (-129.87,-110.24) and (-131.94,-112.12) .. (-130.43,-114.54)
 .. controls (-128.92,-116.95) and (-125.46,-116.03) .. (-123.70,-113.05)
 .. controls (-121.93,-110.07) and (-118.99,-108.77) .. (-120.74,-107.79)
 .. controls (-122.50,-106.80) and (-123.47,-104.41) .. cycle
));
ATTR__height := -1;
drawoptions();
l_chimney(((-10.81,-16.42)
 .. controls (-14.71,-18.82) and (-18.05,-24.72) .. (-17.46,-27.63)
 .. controls (-16.88,-30.55) and (-14.00,-34.47) .. (-10.00,-33.57)
 .. controls (-5.99,-32.68) and (9.33,-24.94) .. (6.81,-21.04)
 .. controls (4.30,-17.13) and (-2.64,-11.40) .. cycle
));
ATTR__height := -1;
drawoptions();
l_chimney(((52.02,42.95)
 .. controls (48.47,40.24) and (42.18,29.36) .. (44.74,26.36)
 .. controls (47.30,23.35) and (64.25,19.67) .. (64.80,27.57)
 .. controls (65.36,35.47) and (65.46,41.41) .. (61.89,42.12)
 .. controls (58.32,42.83) and (55.57,45.67) .. cycle
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-8.88,-42.75) -- (37.65,-26.83)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-8.88,-42.75) -- (-93.56,-91.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((101.04,105.72) -- (86.49,68.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((101.04,105.72) -- (113.50,124.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((113.50,124.95) -- (101.04,105.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((113.50,124.95) -- (160.92,102.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((163.34,75.95) -- (160.92,102.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((160.92,102.11) -- (113.50,124.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((160.92,102.11) -- (163.34,75.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((160.92,102.11) -- (51.77,21.69)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((51.77,21.69) -- (160.92,102.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((51.77,21.69) -- (37.65,-26.83)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((37.65,-26.83) -- (51.77,21.69)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((37.65,-26.83) -- (-8.88,-42.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-93.56,-91.80) -- (-8.88,-42.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-93.56,-91.80) -- (-110.45,-99.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-110.45,-99.53) -- (-93.56,-91.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-110.45,-99.53) -- (-136.42,-114.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-136.42,-114.81) -- (-110.45,-99.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-136.42,-114.81) -- (-198.92,-94.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-198.92,-94.97) -- (-136.42,-114.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-198.92,-94.97) -- (-207.34,-99.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-207.34,-99.03) -- (-198.92,-94.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-207.34,-99.03) -- (-202.87,-52.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-202.87,-52.81) -- (-207.34,-99.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-202.87,-52.81) -- (-211.38,-23.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-211.38,-23.86) -- (-202.87,-52.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-211.38,-23.86) -- (-218.32,-11.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-218.32,-11.44) -- (-211.38,-23.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-218.32,-11.44) -- (-221.28,0.01)));
endfig;
beginfig(14);
draw_upscrap(1)(1,((142.38,97.77)
 .. controls (140.75,93.88) and (103.41,77.81) .. (96.99,71.63)
 .. controls (90.46,65.35) and (47.20,52.03) .. (44.07,46.21)
 .. controls (39.52,37.78) and (43.72,8.57) .. (36.35,1.35)
 .. controls (31.61,-3.28) and (18.45,11.57) .. (2.29,5.13)
 .. controls (-13.87,-1.32) and (-19.47,-28.08) .. (-22.70,-35.49)
 .. controls (-25.94,-42.91) and (-90.91,-83.07) .. (-94.27,-85.44)
 .. controls (-97.63,-87.80) and (-117.24,-83.27) .. (-120.47,-83.11)
 .. controls (-123.71,-82.96) and (-136.55,-87.76) .. (-140.95,-96.92)
 .. controls (-145.35,-106.08) and (-190.92,-94.19) .. (-194.46,-92.94)
 .. controls (-198.01,-91.69) and (-200.77,-89.03) .. (-201.06,-87.58)
),
1,((-201.06,-87.58)
 .. controls (-201.35,-86.12) and (-200.43,-59.14) .. (-198.15,-56.72)
 .. controls (-195.87,-54.31) and (-185.77,-54.07) .. (-185.19,-49.41)
 .. controls (-184.61,-44.75) and (-177.72,-40.03) .. (-177.31,-35.37)
 .. controls (-176.38,-24.55) and (-186.00,-13.33) .. (-182.69,-4.47)
 .. controls (-179.39,4.38) and (-207.39,14.36) .. (-215.81,11.52)
 .. controls (-224.24,8.68) and (-222.66,-3.65) .. (-224.67,-7.88)
 .. controls (-226.67,-12.11) and (-208.86,-16.57) .. (-223.96,-30.99)
 .. controls (-228.28,-35.11) and (-206.22,-52.01) .. (-205.34,-56.38)
 .. controls (-204.47,-60.75) and (-209.86,-98.33) .. (-208.95,-101.98)
),
1,((-208.95,-101.98)
 .. controls (-208.04,-105.62) and (-198.73,-99.22) .. (-196.55,-98.96)
 .. controls (-194.38,-98.71) and (-136.20,-118.41) .. (-136.20,-118.41)
),
1,((-136.20,-118.41)
 .. controls (-132.21,-117.87) and (-111.10,-113.47) .. (-106.79,-106.11)
 .. controls (-102.47,-98.74) and (-97.76,-98.25) .. (-94.46,-96.96)
 .. controls (-91.15,-95.68) and (-83.43,-100.01) .. (-81.36,-94.34)
 .. controls (-79.29,-88.67) and (-12.82,-47.50) .. (-3.27,-43.62)
 .. controls (6.29,-39.75) and (38.94,-35.17) .. (42.96,-26.36)
 .. controls (46.98,-17.54) and (57.77,0.87) .. (61.71,4.11)
 .. controls (65.10,6.90) and (89.70,28.19) .. (95.49,36.20)
 .. controls (101.27,44.22) and (133.54,74.76) .. (152.19,80.54)
),
1,((152.19,80.54)
 .. controls (157.91,83.33) and (160.48,72.76) .. (161.69,71.80)
 .. controls (162.91,70.85) and (215.10,80.98) .. (217.13,81.97)
),
1,((217.13,81.97)
 .. controls (219.16,82.95) and (225.52,84.09) .. (226.80,84.57)
),
1,((225.31,91.13)
 .. controls (223.88,91.38) and (216.27,90.48) .. (214.82,90.37)
),
1,((214.82,90.37)
 .. controls (213.38,90.25) and (173.78,83.67) .. (168.32,82.48)
 .. controls (162.86,81.30) and (161.61,89.11) .. (163.69,91.17)
 .. controls (165.18,92.65) and (162.26,102.95) .. (161.45,104.79)
 .. controls (160.64,106.63) and (142.78,117.57) .. (139.08,119.37)
 .. controls (135.38,121.17) and (111.10,125.92) .. (108.20,125.52)
 .. controls (105.29,125.12) and (96.42,108.96) .. (95.25,107.03)
 .. controls (94.07,105.11) and (87.71,88.65) .. (87.71,88.65)
),
1,((112.01,88.22)
 .. controls (111.94,90.56) and (102.41,98.58) .. (103.91,99.77)
 .. controls (105.41,100.96) and (113.31,100.41) .. (113.74,101.83)
 .. controls (114.17,103.25) and (114.63,112.96) .. (116.43,116.84)
 .. controls (118.24,120.72) and (141.24,107.91) .. (145.61,105.18)
 .. controls (149.99,102.45) and (143.90,99.49) .. (142.38,97.77)
));
draw_downscrap;
endfig;
beginfig(15);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((142.38,97.77)
 .. controls (140.75,93.88) and (103.41,77.81) .. (96.99,71.63)
 .. controls (90.46,65.35) and (47.20,52.03) .. (44.07,46.21)
 .. controls (39.52,37.78) and (43.72,8.57) .. (36.35,1.35)
 .. controls (31.61,-3.28) and (18.45,11.57) .. (2.29,5.13)
 .. controls (-13.87,-1.32) and (-19.47,-28.08) .. (-22.70,-35.49)
 .. controls (-25.94,-42.91) and (-90.91,-83.07) .. (-94.27,-85.44)
 .. controls (-97.63,-87.80) and (-117.24,-83.27) .. (-120.47,-83.11)
 .. controls (-123.71,-82.96) and (-136.55,-87.76) .. (-140.95,-96.92)
 .. controls (-145.35,-106.08) and (-190.92,-94.19) .. (-194.46,-92.94)
 .. controls (-198.01,-91.69) and (-200.77,-89.03) .. (-201.06,-87.58)
));
ATTR__id := "alain-robert_sp1_l2g";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((112.01,88.22)
 .. controls (111.94,90.56) and (102.41,98.58) .. (103.91,99.77)
 .. controls (105.41,100.96) and (113.31,100.41) .. (113.74,101.83)
 .. controls (114.17,103.25) and (114.63,112.96) .. (116.43,116.84)
 .. controls (118.24,120.72) and (141.24,107.91) .. (145.61,105.18)
 .. controls (149.99,102.45) and (143.90,99.49) .. (142.38,97.77)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_presumed(((225.31,91.13)
 .. controls (223.88,91.38) and (216.27,90.48) .. (214.82,90.37)
));
ATTR__id := "alain-robert_sp1_l2d";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((214.82,90.37)
 .. controls (213.38,90.25) and (173.78,83.67) .. (168.32,82.48)
 .. controls (162.86,81.30) and (161.61,89.11) .. (163.69,91.17)
 .. controls (165.18,92.65) and (162.26,102.95) .. (161.45,104.79)
 .. controls (160.64,106.63) and (142.78,117.57) .. (139.08,119.37)
 .. controls (135.38,121.17) and (111.10,125.92) .. (108.20,125.52)
 .. controls (105.29,125.12) and (96.42,108.96) .. (95.25,107.03)
 .. controls (94.07,105.11) and (87.71,88.65) .. (87.71,88.65)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((152.19,80.54)
 .. controls (157.91,83.33) and (160.48,72.76) .. (161.69,71.80)
 .. controls (162.91,70.85) and (215.10,80.98) .. (217.13,81.97)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((217.13,81.97)
 .. controls (219.16,82.95) and (225.52,84.09) .. (226.80,84.57)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-201.06,-87.58)
 .. controls (-201.35,-86.12) and (-200.43,-59.14) .. (-198.15,-56.72)
 .. controls (-195.87,-54.31) and (-185.77,-54.07) .. (-185.19,-49.41)
 .. controls (-184.61,-44.75) and (-177.72,-40.03) .. (-177.31,-35.37)
 .. controls (-176.38,-24.55) and (-186.00,-13.33) .. (-182.69,-4.47)
 .. controls (-179.39,4.38) and (-207.39,14.36) .. (-215.81,11.52)
 .. controls (-224.24,8.68) and (-222.66,-3.65) .. (-224.67,-7.88)
 .. controls (-226.67,-12.11) and (-208.86,-16.57) .. (-223.96,-30.99)
 .. controls (-228.28,-35.11) and (-206.22,-52.01) .. (-205.34,-56.38)
 .. controls (-204.47,-60.75) and (-209.86,-98.33) .. (-208.95,-101.98)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-208.95,-101.98)
 .. controls (-208.04,-105.62) and (-198.73,-99.22) .. (-196.55,-98.96)
 .. controls (-194.38,-98.71) and (-136.20,-118.41) .. (-136.20,-118.41)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-136.20,-118.41)
 .. controls (-132.21,-117.87) and (-111.10,-113.47) .. (-106.79,-106.11)
 .. controls (-102.47,-98.74) and (-97.76,-98.25) .. (-94.46,-96.96)
 .. controls (-91.15,-95.68) and (-83.43,-100.01) .. (-81.36,-94.34)
 .. controls (-79.29,-88.67) and (-12.82,-47.50) .. (-3.27,-43.62)
 .. controls (6.29,-39.75) and (38.94,-35.17) .. (42.96,-26.36)
 .. controls (46.98,-17.54) and (57.77,0.87) .. (61.71,4.11)
 .. controls (65.10,6.90) and (89.70,28.19) .. (95.49,36.20)
 .. controls (101.27,44.22) and (133.54,74.76) .. (152.19,80.54)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-192.08,-12.32)
 .. controls (-192.08,-12.32) and (-179.44,3.30) .. (-180.21,9.83)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-125.00,-125.42)
 -- (-130.66,-107.86)
));
drawoptions();
p_airdraught_winter((-164.39,-119.95),67.4,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-218.32,-11.44),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-211.38,-23.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-202.87,-52.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-207.34,-99.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-198.92,-94.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-136.42,-114.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-110.45,-99.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-93.56,-91.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((37.65,-26.83),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((51.77,21.69),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((160.92,102.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((163.34,75.95),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((113.50,124.95),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((101.04,105.72),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-8.88,-42.75),1,0,"");
endfig;
beginfig(16);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((-209.858,-98.3294),(-208.95,-101.98),(-208.043,-105.624),btex \thwallaltitude \thfb\char45 \char49 \char49 \char55 \mainfont{} etex);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char50 \char53 \mainfont{} etex,(-168.08,-30.76),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char65 \char118 \char97 \char108 \ \char67 \char97 \char118 \char101 \char114 \char110 \char105 \char99 \char111 \char108 \char101 \mainfont{} etex,(-110.54,34.99),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \vtop{\halign{#\hfil\cr\thfb\char80 \char49 \char48 \cr\thfb \char80 \char117 \char105 \char116 \char115 \ \char65 \char108 \char97 \char105 \char110 \cr}}\mainfont{} etex,(88.10,-24.53),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char53 \mainfont{} etex,(171.67,118.90),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char105 \char109 \char112 \char46 \mainfont{} etex,(230.64,100.97),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char63 \mainfont{} etex,(55.54,33.60),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char63 \mainfont{} etex,(-5.92,-23.68),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char63 \mainfont{} etex,(-119.07,-91.47),0.0,p_label_mode_label);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \mainfont{} etex, (-218.32, -11.44), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \mainfont{} etex, (-211.38, -23.86), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \mainfont{} etex, (-202.87, -52.81), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \mainfont{} etex, (-207.34, -99.03), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char57 \mainfont{} etex, (-198.92, -94.97), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char80 \char84 \char82 \char50 \mainfont{} etex, (-136.42, -114.81), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \mainfont{} etex, (-110.45, -99.53), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char50 \mainfont{} etex, (-93.56, -91.80), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char80 \char84 \char82 \char51 \mainfont{} etex, (37.65, -26.83), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char53 \mainfont{} etex, (51.77, 21.69), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char54 \mainfont{} etex, (160.92, 102.11), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char55 \mainfont{} etex, (163.34, 75.95), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char56 \mainfont{} etex, (113.50, 124.95), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char57 \mainfont{} etex, (101.04, 105.72), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char51 \mainfont{} etex, (-8.88, -42.75), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "sp_cav_pullover_0@Master";
ATTR__scrap := "sp_cav_pullover_0";
beginfig(17);
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.67,4.18) -- (-28.88,26.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.67,4.18) -- (1.28,-12.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.28,-12.61) -- (18.01,-7.50)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.28,-12.61) -- (0.95,-2.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.28,-12.61) -- (4.67,4.18)));
endfig;
beginfig(18);
draw_upscrap(1)(1,((3.58,1.67)
 .. controls (7.24,7.65) and (-1.93,12.63) .. (-1.93,12.63)
),
1,((-6.65,8.78)
 .. controls (-6.65,8.78) and (2.46,6.00) .. (-2.02,-0.19)
));
draw_downscrap;
endfig;
beginfig(19);
ATTR__id := "l00_cav_pullover";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.65,8.78)
 .. controls (-6.65,8.78) and (2.46,6.00) .. (-2.02,-0.19)
));
ATTR__id := "l0_cav_pullover";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.58,1.67)
 .. controls (7.24,7.65) and (-1.93,12.63) .. (-1.93,12.63)
));
ATTR__stationflag_splay := false;
ATTR__id := "";
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.28,-12.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((4.67,4.18),1,0,"");
endfig;
beginfig(20);
drawoptions();
p_label.urt(btex \thstationname \thfb\char48 \mainfont{} etex, (1.28, -12.61), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \mainfont{} etex, (4.67, 4.18), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "0-100_sp4@Master";
ATTR__scrap := "0-100_sp4";
beginfig(21);
current_src := "datas/0-100/0-100_p.th2 [1048]";
string area_border[];
area_border[1] := "l132-423-332";
drawoptions();
a_water(buildcycle(((28.26,-18.56)
 .. controls (28.26,-18.56) and (26.63,-25.63) .. (24.65,-26.92)
 .. controls (22.48,-28.34) and (24.05,-32.71) .. (31.80,-31.46)
 .. controls (39.81,-30.17) and (38.21,-31.52) .. (42.02,-32.83)
 .. controls (45.88,-34.16) and (49.87,-31.21) .. (50.19,-28.98)
 .. controls (50.51,-26.74) and (52.23,-24.59) .. (51.27,-21.17)
 .. controls (50.31,-17.76) and (50.77,-16.16) .. (46.15,-14.85)
 .. controls (39.46,-12.96) and (35.77,-14.60) .. (33.99,-14.53)
 .. controls (32.22,-14.46) and (28.26,-18.56) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((51.82,-15.59)
 .. controls (31.62,-6.09) and (26.08,-18.70) .. (26.08,-18.70)
));
ATTR__height := -1;
drawoptions();
l_pit(((-11.44,67.32)
 .. controls (-24.08,69.39) and (-22.22,57.85) .. (-22.22,57.85)
));
ATTR__height := -1;
drawoptions();
l_pit(((41.40,18.64)
 .. controls (33.35,25.50) and (13.93,24.48) .. (8.74,23.32)
 .. controls (3.58,22.16) and (8.58,5.57) .. (8.58,5.57)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.85,64.30) -- (1.47,44.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.85,64.30) -- (-45.40,73.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.47,44.56) -- (25.35,3.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.47,44.56) -- (-26.85,64.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((25.35,3.57) -- (38.47,-26.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((25.35,3.57) -- (1.47,44.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((38.47,-26.76) -- (-62.91,-51.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((38.47,-26.76) -- (25.35,3.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.58,-61.63) -- (-45.85,-56.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.58,-61.63) -- (-62.91,-51.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.58,-61.63) -- (-59.19,-44.85)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.91,-51.07) -- (-62.58,-61.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-62.91,-51.07) -- (38.47,-26.76)));
endfig;
beginfig(22);
draw_upscrap(1)(1,((-38.80,-62.73)
 .. controls (-38.80,-62.73) and (-62.31,-53.73) .. (-52.59,-53.98)
 .. controls (-43.09,-54.23) and (4.52,-46.51) .. (4.52,-46.51)
 -- (45.65,-34.15)
 .. controls (45.65,-34.15) and (57.21,-32.74) .. (50.89,-11.95)
 .. controls (44.56,8.85) and (41.40,18.64) .. (41.40,18.64)
),
1,((41.40,18.64)
 .. controls (41.40,18.64) and (29.78,37.32) .. (14.84,46.99)
 .. controls (0.07,56.54) and (1.51,62.78) .. (-11.44,67.32)
 .. controls (-24.82,72.02) and (-43.87,72.20) .. (-43.87,72.20)
),
1,((-47.78,65.58)
 .. controls (-38.27,70.85) and (-33.12,62.31) .. (-27.97,61.67)
 .. controls (-22.81,61.03) and (-9.41,42.74) .. (-9.41,42.74)
 -- (8.58,5.57)
 .. controls (8.58,5.57) and (15.61,-7.94) .. (15.82,-9.08)
 .. controls (16.02,-10.22) and (18.42,-10.74) .. (24.01,-15.26)
 .. controls (29.52,-19.71) and (25.00,-23.33) .. (23.38,-26.65)
 .. controls (21.77,-29.97) and (-55.40,-48.96) .. (-55.40,-48.96)
),
1,((-55.40,-48.96)
 .. controls (-55.40,-48.96) and (-62.20,-50.51) .. (-60.27,-47.36)
),
1,((-65.88,-49.22)
 .. controls (-65.88,-49.22) and (-62.52,-57.60) .. (-74.53,-58.76)
 .. controls (-79.96,-59.29) and (-81.04,-61.89) .. (-81.04,-61.89)
),
1,((-79.03,-63.10)
 -- (-73.60,-60.39)
 .. controls (-73.60,-60.39) and (-68.60,-59.28) .. (-63.62,-61.73)
 .. controls (-48.03,-69.40) and (-47.38,-68.85) .. (-47.38,-68.85)
));
draw_downscrap;
endfig;
beginfig(23);
ATTR__id := "l1_cav_entree";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-55.40,-48.96)
 .. controls (-55.40,-48.96) and (-62.20,-50.51) .. (-60.27,-47.36)
));
ATTR__id := "l2_cav_entree";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-65.88,-49.22)
 .. controls (-65.88,-49.22) and (-62.52,-57.60) .. (-74.53,-58.76)
 .. controls (-79.96,-59.29) and (-81.04,-61.89) .. (-81.04,-61.89)
));
ATTR__id := "l3_cav_entree";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-79.03,-63.10)
 -- (-73.60,-60.39)
 .. controls (-73.60,-60.39) and (-68.60,-59.28) .. (-63.62,-61.73)
 .. controls (-48.03,-69.40) and (-47.38,-68.85) .. (-47.38,-68.85)
));
ATTR__id := "l5_cav_entree";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-38.80,-62.73)
 .. controls (-38.80,-62.73) and (-62.31,-53.73) .. (-52.59,-53.98)
 .. controls (-43.09,-54.23) and (4.52,-46.51) .. (4.52,-46.51)
 -- (45.65,-34.15)
 .. controls (45.65,-34.15) and (57.21,-32.74) .. (50.89,-11.95)
 .. controls (44.56,8.85) and (41.40,18.64) .. (41.40,18.64)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-59.42,-54.00)
 .. controls (-59.42,-54.00) and (-65.88,-57.14) .. (-35.46,-66.22)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((14.30,-34.74)
 -- (1.40,-39.37)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-1.96,47.00)
 .. controls (-1.96,47.00) and (3.37,38.24) .. (6.21,32.24)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((41.40,18.64)
 .. controls (41.40,18.64) and (29.78,37.32) .. (14.84,46.99)
 .. controls (0.07,56.54) and (1.51,62.78) .. (-11.44,67.32)
 .. controls (-24.82,72.02) and (-43.87,72.20) .. (-43.87,72.20)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-47.78,65.58)
 .. controls (-38.27,70.85) and (-33.12,62.31) .. (-27.97,61.67)
 .. controls (-22.81,61.03) and (-9.41,42.74) .. (-9.41,42.74)
 -- (8.58,5.57)
 .. controls (8.58,5.57) and (15.61,-7.94) .. (15.82,-9.08)
 .. controls (16.02,-10.22) and (18.42,-10.74) .. (24.01,-15.26)
 .. controls (29.52,-19.71) and (25.00,-23.33) .. (23.38,-26.65)
 .. controls (21.77,-29.97) and (-55.40,-48.96) .. (-55.40,-48.96)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-62.91,-51.07),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-62.58,-61.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((38.47,-26.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((25.35,3.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.47,44.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-26.85,64.30),1,0,"");
endfig;
beginfig(24);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char80 \char54 \mainfont{} etex,(24.87,57.34),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char80 \char55 \mainfont{} etex,(68.88,6.54),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char82 \char50 \mainfont{} etex,(77.59,-34.25),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char49 \char49 \char50 \mainfont{} etex,(-1.57,-59.74),0.0,p_label_mode_altitude);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \char49 \mainfont{} etex, (-62.91, -51.07), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \char50 \mainfont{} etex, (-62.58, -61.63), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \char48 \mainfont{} etex, (38.47, -26.76), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char57 \mainfont{} etex, (25.35, 3.57), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char56 \mainfont{} etex, (1.47, 44.56), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char55 \mainfont{} etex, (-26.85, 64.30), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "sp_cav_pullover_1@Master";
ATTR__scrap := "sp_cav_pullover_1";
beginfig(25);
ATTR__height := -1;
drawoptions();
l_rockborder(((247.22,-82.13)
 .. controls (247.22,-82.13) and (245.37,-84.92) .. (247.80,-83.95)
 .. controls (252.65,-82.02) and (247.22,-82.13) .. (247.22,-82.13)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-187.34,24.81)
 .. controls (-186.47,24.32) and (-88.67,1.15) .. (-43.12,-1.58)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((249.54,-80.45)
 .. controls (249.54,-80.45) and (243.23,-79.44) .. (245.09,-84.26)
 .. controls (245.88,-86.32) and (245.18,-86.97) .. (248.79,-85.54)
 .. controls (254.88,-83.13) and (249.54,-80.45) .. (249.54,-80.45)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((-411.56,70.52)
 .. controls (-411.56,70.52) and (-438.89,66.52) .. (-413.84,56.50)
));
ATTR__height := -1;
drawoptions();
l_pit(((216.08,-58.57)
 .. controls (199.22,-52.98) and (204.64,-65.70) .. (204.64,-65.70)
));
ATTR__height := -1;
drawoptions();
l_chimney(((367.01,-91.50)
 .. controls (367.01,-91.50) and (350.36,-96.06) .. (362.50,-100.72)
 .. controls (374.63,-105.38) and (381.34,-106.17) .. (388.34,-105.62)
 .. controls (395.34,-105.07) and (408.32,-101.90) .. (397.54,-97.09)
 .. controls (386.76,-92.27) and (367.01,-91.50) .. cycle
));
ATTR__height := -1;
drawoptions();
l_chimney(((138.44,-27.97)
 .. controls (138.44,-27.97) and (83.31,-18.66) .. (133.58,-39.18)
 .. controls (167.51,-53.02) and (138.44,-27.97) .. cycle
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-502.97,66.42) -- (-519.80,77.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-502.97,66.42) -- (-643.32,98.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-502.97,66.42) -- (-430.65,68.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-430.65,68.94) -- (-502.97,66.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-430.65,68.94) -- (-412.16,66.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-412.16,66.29) -- (-430.65,68.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-412.16,66.29) -- (-343.85,48.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-343.85,48.97) -- (-412.16,66.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-343.85,48.97) -- (-307.87,45.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-307.87,45.18) -- (-343.85,48.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-307.87,45.18) -- (-261.81,29.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-261.81,29.37) -- (-307.87,45.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-261.81,29.37) -- (-204.02,28.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-204.02,28.25) -- (-261.81,29.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-204.02,28.25) -- (-112.83,7.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-112.83,7.90) -- (-204.02,28.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-112.83,7.90) -- (12.35,-9.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((12.35,-9.42) -- (-112.83,7.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((12.35,-9.42) -- (43.54,-13.71)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((43.54,-13.71) -- (12.35,-9.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((43.54,-13.71) -- (118.40,-18.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((118.40,-18.29) -- (43.54,-13.71)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((118.40,-18.29) -- (136.69,-33.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((136.69,-33.47) -- (118.40,-18.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((136.69,-33.47) -- (204.90,-54.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((204.90,-54.24) -- (136.69,-33.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((204.90,-54.24) -- (211.90,-79.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((211.90,-79.28) -- (204.90,-54.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((211.90,-79.28) -- (248.79,-85.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((248.79,-85.54) -- (211.90,-79.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((248.79,-85.54) -- (256.04,-81.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((256.04,-81.51) -- (248.79,-85.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((256.04,-81.51) -- (395.17,-92.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((395.17,-92.17) -- (256.04,-81.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((395.17,-92.17) -- (474.35,-98.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((474.35,-98.84) -- (395.17,-92.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((474.35,-98.84) -- (507.90,-121.49)));
endfig;
beginfig(26);
draw_upscrap(1)(1,((501.29,-113.04)
 .. controls (490.62,-110.50) and (489.12,-99.57) .. (474.35,-98.84)
 .. controls (472.13,-98.73) and (394.93,-90.88) .. (394.04,-90.61)
 .. controls (393.16,-90.34) and (264.63,-79.39) .. (256.11,-78.97)
 .. controls (247.61,-78.55) and (244.93,-78.42) .. (244.93,-78.42)
 .. controls (244.93,-78.42) and (229.54,-81.43) .. (220.89,-66.33)
 .. controls (212.18,-51.12) and (209.07,-54.14) .. (208.19,-53.65)
 .. controls (207.31,-53.15) and (137.89,-21.41) .. (137.89,-21.41)
 .. controls (137.89,-21.41) and (125.59,-16.44) .. (118.90,-15.20)
 .. controls (112.21,-13.96) and (54.73,-2.48) .. (45.61,-0.92)
 .. controls (36.51,0.63) and (-0.51,-2.33) .. (-26.28,2.08)
 .. controls (-61.54,8.12) and (-77.44,41.08) .. (-118.51,43.14)
 .. controls (-131.74,43.80) and (-195.46,28.83) .. (-205.94,30.70)
 .. controls (-216.40,32.56) and (-262.21,37.03) .. (-262.21,37.03)
 -- (-310.18,48.11)
),
1,((-310.18,48.11)
 -- (-343.56,53.39)
 .. controls (-343.56,53.39) and (-400.11,69.95) .. (-410.44,70.47)
 .. controls (-420.71,70.98) and (-429.69,70.55) .. (-429.69,70.55)
 .. controls (-429.69,70.55) and (-476.59,68.60) .. (-500.99,80.37)
),
1,((-502.97,66.42)
 .. controls (-502.97,66.42) and (-499.23,65.00) .. (-490.94,64.59)
 .. controls (-482.65,64.18) and (-456.49,65.36) .. (-447.83,63.14)
 .. controls (-439.16,60.92) and (-417.34,58.25) .. (-413.84,56.50)
 .. controls (-410.33,54.74) and (-358.98,51.02) .. (-351.90,48.64)
 .. controls (-344.82,46.26) and (-344.45,44.67) .. (-343.10,44.61)
 .. controls (-341.76,44.54) and (-313.82,42.68) .. (-309.40,41.34)
 .. controls (-304.97,39.99) and (-261.81,29.37) .. (-261.81,29.37)
 .. controls (-261.81,29.37) and (-224.19,24.63) .. (-210.11,19.00)
 .. controls (-196.01,13.35) and (-176.32,-6.10) .. (-110.16,-9.93)
),
1,reverse ((204.72,-77.94)
 .. controls (204.72,-77.94) and (208.50,-65.66) .. (199.55,-59.53)
 .. controls (190.66,-53.45) and (135.74,-45.14) .. (135.74,-45.14)
 -- (110.86,-31.66)
 .. controls (110.86,-31.66) and (93.00,-22.27) .. (87.11,-21.32)
 .. controls (67.25,-18.12) and (45.71,-21.34) .. (45.71,-21.34)
 .. controls (45.71,-21.34) and (10.94,-23.14) .. (6.80,-20.69)
 .. controls (2.65,-18.25) and (-101.79,-9.00) .. (-110.16,-9.93)
),
1,((204.72,-77.94)
 .. controls (204.72,-77.94) and (203.50,-83.69) .. (208.77,-82.66)
 .. controls (211.51,-82.12) and (241.47,-89.25) .. (248.44,-89.14)
 .. controls (251.57,-89.10) and (252.62,-86.18) .. (258.65,-86.51)
 .. controls (312.47,-89.44) and (339.45,-98.54) .. (349.65,-101.20)
 .. controls (370.96,-106.77) and (379.64,-113.06) .. (398.66,-106.14)
 .. controls (417.68,-99.22) and (449.55,-100.37) .. (471.43,-104.16)
 .. controls (493.22,-107.94) and (484.68,-112.46) .. (496.58,-116.88)
));
draw_downscrap;
endfig;
beginfig(27);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((204.72,-77.94)
 .. controls (204.72,-77.94) and (203.50,-83.69) .. (208.77,-82.66)
 .. controls (211.51,-82.12) and (241.47,-89.25) .. (248.44,-89.14)
 .. controls (251.57,-89.10) and (252.62,-86.18) .. (258.65,-86.51)
 .. controls (312.47,-89.44) and (339.45,-98.54) .. (349.65,-101.20)
 .. controls (370.96,-106.77) and (379.64,-113.06) .. (398.66,-106.14)
 .. controls (417.68,-99.22) and (449.55,-100.37) .. (471.43,-104.16)
 .. controls (493.22,-107.94) and (484.68,-112.46) .. (496.58,-116.88)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((501.29,-113.04)
 .. controls (490.62,-110.50) and (489.12,-99.57) .. (474.35,-98.84)
 .. controls (472.13,-98.73) and (394.93,-90.88) .. (394.04,-90.61)
 .. controls (393.16,-90.34) and (264.63,-79.39) .. (256.11,-78.97)
 .. controls (247.61,-78.55) and (244.93,-78.42) .. (244.93,-78.42)
 .. controls (244.93,-78.42) and (229.54,-81.43) .. (220.89,-66.33)
 .. controls (212.18,-51.12) and (209.07,-54.14) .. (208.19,-53.65)
 .. controls (207.31,-53.15) and (137.89,-21.41) .. (137.89,-21.41)
 .. controls (137.89,-21.41) and (125.59,-16.44) .. (118.90,-15.20)
 .. controls (112.21,-13.96) and (54.73,-2.48) .. (45.61,-0.92)
 .. controls (36.51,0.63) and (-0.51,-2.33) .. (-26.28,2.08)
 .. controls (-61.54,8.12) and (-77.44,41.08) .. (-118.51,43.14)
 .. controls (-131.74,43.80) and (-195.46,28.83) .. (-205.94,30.70)
 .. controls (-216.40,32.56) and (-262.21,37.03) .. (-262.21,37.03)
 -- (-310.18,48.11)
));
ATTR__height := -1;
drawoptions();
l_gradient(((277.03,-51.48)
 .. controls (277.03,-51.48) and (266.52,-59.27) .. (253.87,-74.37)
));
ATTR__height := -1;
drawoptions();
l_arrow(((-482.36,97.21)
 -- (-498.51,84.97)
),2);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-310.18,48.11)
 -- (-343.56,53.39)
 .. controls (-343.56,53.39) and (-400.11,69.95) .. (-410.44,70.47)
 .. controls (-420.71,70.98) and (-429.69,70.55) .. (-429.69,70.55)
 .. controls (-429.69,70.55) and (-476.59,68.60) .. (-500.99,80.37)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-502.97,66.42)
 .. controls (-502.97,66.42) and (-499.23,65.00) .. (-490.94,64.59)
 .. controls (-482.65,64.18) and (-456.49,65.36) .. (-447.83,63.14)
 .. controls (-439.16,60.92) and (-417.34,58.25) .. (-413.84,56.50)
 .. controls (-410.33,54.74) and (-358.98,51.02) .. (-351.90,48.64)
 .. controls (-344.82,46.26) and (-344.45,44.67) .. (-343.10,44.61)
 .. controls (-341.76,44.54) and (-313.82,42.68) .. (-309.40,41.34)
 .. controls (-304.97,39.99) and (-261.81,29.37) .. (-261.81,29.37)
 .. controls (-261.81,29.37) and (-224.19,24.63) .. (-210.11,19.00)
 .. controls (-196.01,13.35) and (-176.32,-6.10) .. (-110.16,-9.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((204.72,-77.94)
 .. controls (204.72,-77.94) and (208.50,-65.66) .. (199.55,-59.53)
 .. controls (190.66,-53.45) and (135.74,-45.14) .. (135.74,-45.14)
 -- (110.86,-31.66)
 .. controls (110.86,-31.66) and (93.00,-22.27) .. (87.11,-21.32)
 .. controls (67.25,-18.12) and (45.71,-21.34) .. (45.71,-21.34)
 .. controls (45.71,-21.34) and (10.94,-23.14) .. (6.80,-20.69)
 .. controls (2.65,-18.25) and (-101.79,-9.00) .. (-110.16,-9.93)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((474.35,-98.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((395.17,-92.17),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((256.04,-81.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((248.79,-85.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((211.90,-79.28),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((204.90,-54.24),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((136.69,-33.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((118.40,-18.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((43.54,-13.71),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((12.35,-9.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-112.83,7.90),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-204.02,28.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-261.81,29.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-307.87,45.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-343.85,48.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-412.16,66.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-430.65,68.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-502.97,66.42),1,0,"");
endfig;
beginfig(28);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char97 \char110 \char99 \char105 \char101 \char110 \ \char116 \char101 \char114 \char109 \char105 \char110 \char117 \char115 \mainfont{} etex,(-450.37,115.60),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char83 \char116 \char97 \char108 \char97 \char103 \char109 \char105 \char116 \char101 \ \char101 \char110 \ \char112 \char108 \char101 \char105 \char110 \ \char109 \char105 \char108 \char108 \char105 \char101 \char117 \ \char100 \char117 \ \char112 \char97 \char115 \char115 \char97 \char103 \char101 \ \char33 \char33 \char33 \mainfont{} etex,(349.45,-37.77),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char82 \char52 \ \char67 \char111 \char117 \char108 \thfc\char233 \thfb\char101 \ \char100 \char101 \ \char99 \char97 \char108 \char99 \char105 \char116 \char101 \ \thfc\char184 \ \thfb\char101 \char115 \char99 \char97 \char108 \char97 \char100 \char101 \char114 \mainfont{} etex,(-376.28,83.37),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char82 \char50 \mainfont{} etex,(231.49,-47.45),0.0,p_label_mode_label);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \mainfont{} etex, (474.35, -98.84), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \mainfont{} etex, (395.17, -92.17), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \mainfont{} etex, (256.04, -81.51), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \mainfont{} etex, (248.79, -85.54), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \mainfont{} etex, (211.90, -79.28), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \mainfont{} etex, (204.90, -54.24), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \mainfont{} etex, (136.69, -33.47), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char57 \mainfont{} etex, (118.40, -18.29), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \mainfont{} etex, (43.54, -13.71), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \mainfont{} etex, (12.35, -9.42), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char50 \mainfont{} etex, (-112.83, 7.90), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char51 \mainfont{} etex, (-204.02, 28.25), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char52 \mainfont{} etex, (-261.81, 29.37), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char53 \mainfont{} etex, (-307.87, 45.18), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char54 \mainfont{} etex, (-343.85, 48.97), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char55 \mainfont{} etex, (-412.16, 66.29), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char56 \mainfont{} etex, (-430.65, 68.94), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char57 \mainfont{} etex, (-502.97, 66.42), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "0-100_sp3@Master";
ATTR__scrap := "0-100_sp3";
beginfig(29);
current_src := "datas/0-100/0-100_p.th2 [906]";
string area_border[];
area_border[1] := "l259-785-561";
drawoptions();
a_clay(buildcycle(((230.83,53.28)
 -- (246.22,30.96)
 -- (311.27,45.44)
 -- (303.64,64.93)
 -- (269.51,71.75)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((366.39,70.07)
 .. controls (369.24,73.32) and (363.18,83.05) .. (363.18,83.05)
));
ATTR__height := -1;
drawoptions();
l_pit(((394.12,85.67)
 .. controls (394.12,85.67) and (392.03,74.74) .. (395.50,72.10)
));
ATTR__height := -1;
drawoptions();
l_pit(((312.23,70.37)
 .. controls (312.23,70.37) and (307.69,60.01) .. (309.69,59.46)
 .. controls (311.69,58.92) and (314.82,58.54) .. (317.52,58.42)
 .. controls (320.21,58.29) and (324.83,56.04) .. (325.19,54.23)
));
ATTR__height := -1;
drawoptions();
l_pit(((-162.12,-79.83)
 .. controls (-161.42,-79.42) and (-155.97,-70.66) .. (-155.77,-64.39)
 .. controls (-155.58,-58.15) and (-165.30,-55.38) .. (-165.30,-55.38)
));
ATTR__height := -1;
drawoptions();
l_pit(((-290.75,-65.74)
 .. controls (-290.75,-65.74) and (-336.85,-92.88) .. (-296.47,-97.62)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-151.61,-66.10) -- (-133.06,-74.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-151.61,-66.10) -- (-182.25,-65.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-300.20,-91.74) -- (-284.64,-81.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-300.20,-91.74) -- (-288.04,-42.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-300.20,-91.74) -- (-266.48,-85.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-266.48,-85.04) -- (-300.20,-91.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-266.48,-85.04) -- (-242.74,-65.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-242.74,-65.62) -- (-266.48,-85.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-242.74,-65.62) -- (-182.25,-65.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-182.25,-65.94) -- (-242.74,-65.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-182.25,-65.94) -- (-151.61,-66.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-182.25,-65.94) -- (-167.35,-72.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-167.35,-72.55) -- (-182.25,-65.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-167.35,-72.55) -- (-154.66,-61.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-154.66,-61.30) -- (-167.35,-72.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-154.66,-61.30) -- (-66.74,-62.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-66.74,-62.32) -- (-154.66,-61.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-66.74,-62.32) -- (1.20,-51.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.20,-51.02) -- (-66.74,-62.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1.20,-51.02) -- (40.73,-54.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.73,-54.80) -- (1.20,-51.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((40.73,-54.80) -- (106.50,-34.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.50,-34.39) -- (40.73,-54.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.50,-34.39) -- (131.02,-34.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((131.02,-34.03) -- (106.50,-34.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((131.02,-34.03) -- (180.51,-4.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((180.51,-4.13) -- (131.02,-34.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((180.51,-4.13) -- (211.99,36.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((211.99,36.95) -- (180.51,-4.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((211.99,36.95) -- (268.81,67.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((268.81,67.09) -- (211.99,36.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((268.81,67.09) -- (285.20,47.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((285.20,47.30) -- (268.81,67.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((285.20,47.30) -- (324.56,58.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((324.56,58.61) -- (285.20,47.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((324.56,58.61) -- (317.90,91.55)));
endfig;
beginfig(30);
draw_upscrap(1)(1,((346.11,93.08)
 .. controls (341.48,94.88) and (314.94,85.11) .. (314.42,74.09)
 .. controls (313.74,59.48) and (294.63,55.00) .. (288.97,54.15)
 .. controls (283.30,53.30) and (285.67,55.89) .. (282.21,58.99)
 .. controls (278.75,62.08) and (272.92,67.53) .. (268.81,67.09)
 .. controls (264.70,66.64) and (253.69,60.00) .. (241.65,53.68)
 .. controls (229.43,47.27) and (217.72,41.70) .. (211.00,37.53)
 .. controls (191.72,25.56) and (176.04,6.49) .. (174.42,6.08)
 .. controls (172.81,5.68) and (137.66,-25.27) .. (131.28,-28.74)
 .. controls (125.84,-31.71) and (53.90,-46.61) .. (43.34,-51.29)
 .. controls (32.73,-55.99) and (2.12,-48.95) .. (2.12,-48.95)
 .. controls (2.12,-48.95) and (-56.41,-51.62) .. (-65.89,-52.31)
 .. controls (-75.39,-53.00) and (-156.33,-56.06) .. (-165.30,-55.38)
 .. controls (-174.33,-54.68) and (-231.23,-64.12) .. (-241.07,-65.02)
 .. controls (-251.17,-65.95) and (-343.65,-62.96) .. (-376.02,-82.25)
),
1,((-376.02,-82.25)
 .. controls (-376.02,-82.25) and (-379.55,-85.53) .. (-397.40,-81.44)
),
1,((-397.13,-90.15)
 .. controls (-360.81,-93.68) and (-328.45,-94.23) .. (-322.75,-97.21)
 .. controls (-317.66,-99.87) and (-251.06,-94.01) .. (-247.70,-94.37)
 .. controls (-244.34,-94.73) and (-164.39,-79.72) .. (-162.12,-79.83)
 .. controls (-159.85,-79.94) and (-156.42,-75.84) .. (-153.99,-73.70)
),
1,reverse ((-150.08,-67.07)
 .. controls (-150.08,-67.07) and (-151.65,-71.52) .. (-153.99,-73.70)
),
1,((-150.08,-67.07)
 -- (-148.99,-63.63)
 .. controls (-148.99,-63.63) and (-74.33,-64.76) .. (-65.93,-63.57)
 .. controls (-59.77,-62.70) and (0.29,-54.28) .. (2.56,-54.16)
 .. controls (4.82,-54.04) and (31.71,-58.64) .. (37.58,-58.68)
 .. controls (43.65,-58.72) and (106.77,-39.74) .. (107.47,-39.35)
 .. controls (108.18,-38.95) and (128.07,-37.10) .. (131.60,-35.66)
 .. controls (143.87,-30.65) and (170.17,-12.32) .. (180.51,-4.13)
 .. controls (190.80,4.03) and (221.12,18.61) .. (222.84,21.67)
 .. controls (224.57,24.74) and (245.13,46.32) .. (245.13,46.32)
 .. controls (245.13,46.32) and (267.64,60.57) .. (270.77,60.20)
 .. controls (273.91,59.82) and (283.88,46.29) .. (284.99,46.01)
 .. controls (286.10,45.73) and (321.63,55.07) .. (324.86,56.72)
 .. controls (328.09,58.36) and (360.65,74.56) .. (369.01,73.10)
),
1,((369.01,73.10)
 .. controls (370.60,73.48) and (397.69,75.60) .. (397.69,75.60)
),
1,((396.31,84.45)
 .. controls (395.18,84.27) and (369.14,80.75) .. (369.14,80.75)
),
1,((369.14,80.75)
 .. controls (353.17,75.64) and (363.28,90.03) .. (346.11,93.08)
));
draw_downscrap;
endfig;
beginfig(31);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((346.11,93.08)
 .. controls (341.48,94.88) and (314.94,85.11) .. (314.42,74.09)
 .. controls (313.74,59.48) and (294.63,55.00) .. (288.97,54.15)
 .. controls (283.30,53.30) and (285.67,55.89) .. (282.21,58.99)
 .. controls (278.75,62.08) and (272.92,67.53) .. (268.81,67.09)
 .. controls (264.70,66.64) and (253.69,60.00) .. (241.65,53.68)
 .. controls (229.43,47.27) and (217.72,41.70) .. (211.00,37.53)
 .. controls (191.72,25.56) and (176.04,6.49) .. (174.42,6.08)
 .. controls (172.81,5.68) and (137.66,-25.27) .. (131.28,-28.74)
 .. controls (125.84,-31.71) and (53.90,-46.61) .. (43.34,-51.29)
 .. controls (32.73,-55.99) and (2.12,-48.95) .. (2.12,-48.95)
 .. controls (2.12,-48.95) and (-56.41,-51.62) .. (-65.89,-52.31)
 .. controls (-75.39,-53.00) and (-156.33,-56.06) .. (-165.30,-55.38)
 .. controls (-174.33,-54.68) and (-231.23,-64.12) .. (-241.07,-65.02)
 .. controls (-251.17,-65.95) and (-343.65,-62.96) .. (-376.02,-82.25)
));
ATTR__id := "l4_cav_entree";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-376.02,-82.25)
 .. controls (-376.02,-82.25) and (-379.55,-85.53) .. (-397.40,-81.44)
));
ATTR__id := "l6_cav_entree";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-397.13,-90.15)
 .. controls (-360.81,-93.68) and (-328.45,-94.23) .. (-322.75,-97.21)
 .. controls (-317.66,-99.87) and (-251.06,-94.01) .. (-247.70,-94.37)
 .. controls (-244.34,-94.73) and (-164.39,-79.72) .. (-162.12,-79.83)
 .. controls (-159.85,-79.94) and (-156.42,-75.84) .. (-153.99,-73.70)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-150.08,-67.07)
 -- (-148.99,-63.63)
 .. controls (-148.99,-63.63) and (-74.33,-64.76) .. (-65.93,-63.57)
 .. controls (-59.77,-62.70) and (0.29,-54.28) .. (2.56,-54.16)
 .. controls (4.82,-54.04) and (31.71,-58.64) .. (37.58,-58.68)
 .. controls (43.65,-58.72) and (106.77,-39.74) .. (107.47,-39.35)
 .. controls (108.18,-38.95) and (128.07,-37.10) .. (131.60,-35.66)
 .. controls (143.87,-30.65) and (170.17,-12.32) .. (180.51,-4.13)
 .. controls (190.80,4.03) and (221.12,18.61) .. (222.84,21.67)
 .. controls (224.57,24.74) and (245.13,46.32) .. (245.13,46.32)
 .. controls (245.13,46.32) and (267.64,60.57) .. (270.77,60.20)
 .. controls (273.91,59.82) and (283.88,46.29) .. (284.99,46.01)
 .. controls (286.10,45.73) and (321.63,55.07) .. (324.86,56.72)
 .. controls (328.09,58.36) and (360.65,74.56) .. (369.01,73.10)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((396.31,84.45)
 .. controls (395.18,84.27) and (369.14,80.75) .. (369.14,80.75)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((369.01,73.10)
 .. controls (370.60,73.48) and (397.69,75.60) .. (397.69,75.60)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((321.93,90.40)
 -- (331.91,72.81)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-292.31,-79.60)
 -- (-263.56,-79.68)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((369.14,80.75)
 .. controls (353.17,75.64) and (363.28,90.03) .. (346.11,93.08)
));
drawoptions();
p_airdraught((65.90,-29.78),277.3,2.00,(0,0));
drawoptions();
p_dig((-8.32,-34.70),0.0,0.50,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((324.56,58.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((285.20,47.30),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((268.81,67.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((211.99,36.95),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((180.51,-4.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((131.02,-34.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((106.50,-34.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((40.73,-54.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((1.20,-51.02),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-66.74,-62.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-154.66,-61.30),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-167.35,-72.55),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-182.25,-65.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-242.74,-65.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-266.48,-85.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-300.20,-91.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-151.61,-66.10),1,0,"");
endfig;
beginfig(32);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((360.652,74.5616),(369.01,73.10),(377.366,71.6446),btex \thwallaltitude \thfb\char45 \char57 \char53 \mainfont{} etex);
drawoptions();
p_label(btex \thlabel\thtinysize \thfb\char67 \char104 \char97 \char116 \char105 \accent18 \char101 \char114 \char101 \mainfont{} etex,(260.80,44.23),21.6,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char54 \ \char82 \char101 \char109 \char111 \char110 \char116 \char97 \char110 \char116 \mainfont{} etex,(-293.53,-51.66),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char49 \char48 \mainfont{} etex,(358.39,115.27),0.0,p_label_mode_label);
ATTR__height := -1;
drawoptions();
l_label(btex \thlabel \thsmallsize \thfb\char109 {}\thfc\char233 {}\thfb\char97 {}\char110 {}\char100 {}\char114 {}\char101 {}\ \char100 {}\char101 {}\ \char50 {}\char48 {}\char109 {}\mainfont{} etex,((-47.22,-71.41)
 .. controls (-47.22,-71.41) and (81.81,-69.07) .. (139.69,-51.08)
));
drawoptions();
p_label(btex \thlabel\thtinysize \thfb\char68 \thfc\char233 \thfb\char112 \char97 \char114 \char116 \ \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \ \char115 \char97 \char110 \char115 \ \char67 \char65 \ \char110 \char111 \char110 \ \char116 \char111 \char112 \char111 \mainfont{} etex,(442.83,87.01),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char80 \char54 \mainfont{} etex,(-171.16,-38.65),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char57 \char49 \mainfont{} etex,(-334.70,-116.12),0.0,p_label_mode_altitude);
ATTR__height := -1;
drawoptions();
l_label(btex \thlabel \thhugesize \thfb\char74 {}\char111 {}\char110 {}\char99 {}\char116 {}\char105 {}\char111 {}\char110 {}\ \char108 {}\char101 {}\ \char50 {}\char50 {}\char47 {}\char49 {}\char48 {}\char47 {}\char50 {}\char51 {}\ \char97 {}\char118 {}\char101 {}\char99 {}\ \char108 {}\char97 {}\ \char98 {}\char114 {}\char97 {}\char110 {}\char99 {}\char104 {}\char101 {}\ \char97 {}\char109 {}\char111 {}\char110 {}\char116 {}\ \char100 {}\char101 {}\ \char108 {}\char39 {}\char97 {}\char99 {}\char116 {}\char105 {}\char102 {}\mainfont{} etex,((-441.07,-38.13)
 -- (-335.15,-44.51)
));
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char48 \mainfont{} etex, (324.56, 58.61), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char49 \mainfont{} etex, (285.20, 47.30), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char50 \mainfont{} etex, (268.81, 67.09), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char51 \mainfont{} etex, (211.99, 36.95), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char52 \mainfont{} etex, (180.51, -4.13), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char53 \mainfont{} etex, (131.02, -34.03), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char54 \mainfont{} etex, (106.50, -34.39), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char55 \mainfont{} etex, (40.73, -54.80), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char56 \mainfont{} etex, (1.20, -51.02), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char57 \mainfont{} etex, (-66.74, -62.32), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char48 \mainfont{} etex, (-154.66, -61.30), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char49 \mainfont{} etex, (-167.35, -72.55), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char50 \mainfont{} etex, (-182.25, -65.94), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char52 \mainfont{} etex, (-242.74, -65.62), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char53 \mainfont{} etex, (-266.48, -85.04), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char54 \mainfont{} etex, (-300.20, -91.74), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char51 \mainfont{} etex, (-151.61, -66.10), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "salle-mimine-sup_sp1@Master";
ATTR__scrap := "salle-mimine-sup_sp1";
beginfig(33);
ATTR__height := -1;
drawoptions();
l_pit(((-91.59,-92.45)
 .. controls (-91.59,-92.45) and (-86.53,-25.70) .. (-91.93,-18.07)
));
ATTR__height := -1;
drawoptions();
l_pit(((15.81,65.65)
 .. controls (15.81,65.65) and (-8.69,72.04) .. (-3.72,51.45)
));
ATTR__height := -1;
drawoptions();
l_pit(((129.53,2.44)
 .. controls (124.43,2.18) and (119.69,2.08) .. (119.66,-1.73)
 .. controls (119.63,-5.55) and (125.24,-12.59) .. (127.09,-11.97)
 .. controls (128.95,-11.34) and (143.19,-13.40) .. (141.94,-9.70)
 .. controls (140.70,-5.99) and (134.64,2.71) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((133.62,7.31)
 -- (132.39,1.56)
 -- (138.01,1.25)
 -- (143.02,3.15)
 -- (138.34,3.96)
 -- (139.60,6.98)
 -- (143.02,3.15)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((112.69,-9.35)
 -- (111.01,-13.43)
 -- (113.94,-16.13)
 -- (116.72,-18.47)
 -- (120.92,-15.07)
 -- (113.94,-16.13)
 -- (118.10,-13.46)
 -- (120.92,-15.07)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((12.23,-83.01)
 .. controls (11.26,-80.81) and (5.39,-75.31) .. (0.75,-70.58)
 .. controls (-3.89,-65.86) and (-18.19,-55.99) .. (-24.73,-53.33)
 .. controls (-31.27,-50.68) and (-47.72,-52.05) .. (-53.33,-52.86)
 .. controls (-58.95,-53.67) and (-67.27,-58.32) .. (-68.90,-62.20)
 .. controls (-70.53,-66.09) and (-70.00,-88.82) .. (-69.10,-92.64)
));
ATTR__height := -1;
drawoptions();
l_slope(((-25.48,-39.23)
 .. controls (-30.33,-39.00) and (-68.58,-37.54) .. (-67.30,-47.87)
),0,(0,-1,10.793),(1,-1,10.793));
drawoptions();
p_blocks((-10.75,-54.72),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_slope(((-74.30,-88.43)
 .. controls (-79.52,-62.41) and (-67.30,-47.87) .. (-67.30,-47.87)
),0,(0,-1,14.3906),(1,-1,14.3906));
ATTR__height := -1;
drawoptions();
l_chimney(((-74.32,109.40)
 .. controls (-78.14,108.68) and (-93.64,112.30) .. (-95.44,108.60)
 .. controls (-97.23,104.90) and (-101.12,102.74) .. (-98.90,96.33)
 .. controls (-96.68,89.92) and (-87.81,79.40) .. (-85.34,78.39)
 .. controls (-82.86,77.37) and (-67.19,69.60) .. (-63.16,71.21)
 .. controls (-59.12,72.82) and (-43.46,72.43) .. (-44.15,80.58)
 .. controls (-44.85,88.72) and (-45.18,100.62) .. (-50.87,102.34)
 .. controls (-56.55,104.05) and (-72.34,109.30) .. (-74.32,109.40)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-84.64,96.82) -- (-78.92,95.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-84.64,96.82) -- (-26.83,76.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.83,76.22) -- (-84.64,96.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-26.83,76.22) -- (-2.32,59.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((5.06,64.77) -- (-2.32,59.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((5.06,64.77) -- (72.13,0.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2.32,59.61) -- (-26.83,76.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2.32,59.61) -- (5.06,64.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((72.13,0.19) -- (5.06,64.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((72.13,0.19) -- (126.48,-3.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((72.13,0.19) -- (10.97,5.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((10.97,5.02) -- (72.13,0.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((10.97,5.02) -- (14.03,-55.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.03,-55.89) -- (10.97,5.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.03,-55.89) -- (-17.06,-71.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-17.06,-71.51) -- (14.03,-55.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-17.06,-71.51) -- (-57.87,-84.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((126.48,-3.92) -- (72.13,0.19)));
endfig;
beginfig(34);
draw_upscrap(1)(1,((-44.50,-109.13)
 .. controls (-40.38,-109.69) and (-2.23,-91.70) .. (3.33,-88.36)
 .. controls (8.89,-85.02) and (15.95,-73.10) .. (20.47,-53.68)
 .. controls (25.00,-34.25) and (57.96,-15.68) .. (66.00,-15.53)
 .. controls (74.08,-15.37) and (81.70,-14.20) .. (87.09,-18.30)
 .. controls (92.49,-22.40) and (124.08,-38.91) .. (132.87,-41.03)
 .. controls (141.64,-43.15) and (154.42,-29.40) .. (156.04,-23.33)
 .. controls (157.66,-17.25) and (155.27,-1.69) .. (154.05,2.56)
 .. controls (152.83,6.81) and (132.31,28.86) .. (129.09,30.30)
 .. controls (125.86,31.75) and (102.74,38.51) .. (94.60,39.41)
 .. controls (86.49,40.31) and (33.51,54.08) .. (31.61,55.60)
 .. controls (29.72,57.12) and (9.24,66.86) .. (5.51,67.57)
 .. controls (1.77,68.29) and (-23.63,83.93) .. (-28.40,85.96)
 .. controls (-33.17,87.98) and (-37.38,97.91) .. (-40.80,101.86)
 .. controls (-44.21,105.80) and (-67.38,115.01) .. (-72.40,115.61)
 .. controls (-77.42,116.21) and (-94.69,116.67) .. (-97.46,115.36)
 .. controls (-100.22,114.05) and (-108.66,114.81) .. (-111.18,107.18)
 .. controls (-113.70,99.55) and (-97.66,84.56) .. (-94.94,81.18)
 .. controls (-92.21,77.81) and (-72.39,62.63) .. (-65.83,60.34)
 .. controls (-59.27,58.04) and (-20.30,55.12) .. (-17.69,57.15)
 .. controls (-15.07,59.19) and (-5.08,60.88) .. (-1.70,56.03)
 .. controls (1.67,51.20) and (-5.87,4.82) .. (-8.94,0.47)
 .. controls (-12.01,-3.87) and (-29.00,-34.19) .. (-35.28,-37.32)
 .. controls (-41.56,-40.45) and (-53.07,-36.83) .. (-56.33,-33.80)
 .. controls (-59.60,-30.76) and (-92.95,-20.54) .. (-99.75,-15.89)
 .. controls (-106.56,-11.25) and (-147.64,-26.94) .. (-152.91,-31.73)
 .. controls (-158.18,-36.52) and (-155.78,-46.71) .. (-158.19,-55.60)
 .. controls (-160.59,-64.48) and (-156.33,-80.70) .. (-153.82,-88.39)
 .. controls (-151.31,-96.07) and (-132.26,-107.78) .. (-124.74,-108.50)
 .. controls (-117.22,-109.22) and (-96.20,-91.15) .. (-94.31,-89.26)
 .. controls (-92.42,-87.37) and (-75.10,-86.23) .. (-71.22,-88.04)
 .. controls (-67.35,-89.84) and (-48.61,-108.58) .. cycle
));
draw_downscrap;
endfig;
beginfig(35);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-44.50,-109.13)
 .. controls (-40.38,-109.69) and (-2.23,-91.70) .. (3.33,-88.36)
 .. controls (8.89,-85.02) and (15.95,-73.10) .. (20.47,-53.68)
 .. controls (25.00,-34.25) and (57.96,-15.68) .. (66.00,-15.53)
 .. controls (74.08,-15.37) and (81.70,-14.20) .. (87.09,-18.30)
 .. controls (92.49,-22.40) and (124.08,-38.91) .. (132.87,-41.03)
 .. controls (141.64,-43.15) and (154.42,-29.40) .. (156.04,-23.33)
 .. controls (157.66,-17.25) and (155.27,-1.69) .. (154.05,2.56)
 .. controls (152.83,6.81) and (132.31,28.86) .. (129.09,30.30)
 .. controls (125.86,31.75) and (102.74,38.51) .. (94.60,39.41)
 .. controls (86.49,40.31) and (33.51,54.08) .. (31.61,55.60)
 .. controls (29.72,57.12) and (9.24,66.86) .. (5.51,67.57)
 .. controls (1.77,68.29) and (-23.63,83.93) .. (-28.40,85.96)
 .. controls (-33.17,87.98) and (-37.38,97.91) .. (-40.80,101.86)
 .. controls (-44.21,105.80) and (-67.38,115.01) .. (-72.40,115.61)
 .. controls (-77.42,116.21) and (-94.69,116.67) .. (-97.46,115.36)
 .. controls (-100.22,114.05) and (-108.66,114.81) .. (-111.18,107.18)
 .. controls (-113.70,99.55) and (-97.66,84.56) .. (-94.94,81.18)
 .. controls (-92.21,77.81) and (-72.39,62.63) .. (-65.83,60.34)
 .. controls (-59.27,58.04) and (-20.30,55.12) .. (-17.69,57.15)
 .. controls (-15.07,59.19) and (-5.08,60.88) .. (-1.70,56.03)
 .. controls (1.67,51.20) and (-5.87,4.82) .. (-8.94,0.47)
 .. controls (-12.01,-3.87) and (-29.00,-34.19) .. (-35.28,-37.32)
 .. controls (-41.56,-40.45) and (-53.07,-36.83) .. (-56.33,-33.80)
 .. controls (-59.60,-30.76) and (-92.95,-20.54) .. (-99.75,-15.89)
 .. controls (-106.56,-11.25) and (-147.64,-26.94) .. (-152.91,-31.73)
 .. controls (-158.18,-36.52) and (-155.78,-46.71) .. (-158.19,-55.60)
 .. controls (-160.59,-64.48) and (-156.33,-80.70) .. (-153.82,-88.39)
 .. controls (-151.31,-96.07) and (-132.26,-107.78) .. (-124.74,-108.50)
 .. controls (-117.22,-109.22) and (-96.20,-91.15) .. (-94.31,-89.26)
 .. controls (-92.42,-87.37) and (-75.10,-86.23) .. (-71.22,-88.04)
 .. controls (-67.35,-89.84) and (-48.61,-108.58) .. cycle
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-112.83,114.11)
 -- (-90.93,101.00)
));
ATTR__height := -1;
drawoptions();
l_mapconnection(((132.86,-9.56)
 -- (134.80,-23.47)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((126.48,-3.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-17.06,-71.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((14.03,-55.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((10.97,5.02),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((72.13,0.19),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-2.32,59.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((5.06,64.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-26.83,76.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-84.64,96.82),1,0,"");
endfig;
beginfig(36);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char67 \char104 \char51 \char48 \mainfont{} etex,(-74.50,94.09),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char54 \mainfont{} etex,(19.36,72.13),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char50 \char53 \char63 \mainfont{} etex,(-128.19,-53.24),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char54 \mainfont{} etex,(-31.78,-87.95),0.0,p_label_mode_label);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char54 \mainfont{} etex, (126.48, -3.92), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char53 \mainfont{} etex, (-17.06, -71.51), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char80 \char84 \char82 \char56 \mainfont{} etex, (14.03, -55.89), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char55 \mainfont{} etex, (10.97, 5.02), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char56 \mainfont{} etex, (72.13, 0.19), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char48 \mainfont{} etex, (-2.32, 59.61), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char57 \mainfont{} etex, (5.06, 64.77), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char49 \mainfont{} etex, (-26.83, 76.22), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char50 \mainfont{} etex, (-84.64, 96.82), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "amont-marneux_sp1@Master";
ATTR__scrap := "amont-marneux_sp1";
beginfig(37);
ATTR__height := -1;
drawoptions();
l_pit(((-89.78,-308.68)
 .. controls (-50.35,-305.50) and (-59.97,-272.98) .. (-59.97,-272.98)
));
ATTR__height := -1;
drawoptions();
l_pit(((-123.00,-249.12)
 .. controls (-123.00,-249.12) and (-154.91,-268.75) .. (-151.25,-275.21)
 .. controls (-147.61,-281.62) and (-141.78,-295.69) .. (-128.98,-299.24)
));
ATTR__height := -1;
drawoptions();
l_pit(((-32.47,-77.58)
 .. controls (-32.47,-77.58) and (-1.44,-94.49) .. (12.97,-83.77)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-16.58,-75.77) -- (-18.08,-136.35)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-16.58,-75.77) -- (-20.77,-44.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-20.77,-44.29) -- (-16.58,-75.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-20.77,-44.29) -- (11.34,-17.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-16.58,-75.77) -- (-18.08,-136.35)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-16.58,-75.77) -- (-20.77,-44.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-18.08,-136.35) -- (-28.17,-240.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-18.08,-136.35) -- (-16.58,-75.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.17,-240.80) -- (-102.65,-295.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.17,-240.80) -- (-18.08,-136.35)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-102.65,-295.47) -- (-56.44,-274.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-102.65,-295.47) -- (-28.17,-240.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-56.44,-274.62) -- (-31.85,-290.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-56.44,-274.62) -- (-102.65,-295.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-31.85,-290.60) -- (37.50,-161.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-31.85,-290.60) -- (-56.44,-274.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((37.50,-161.36) -- (78.87,-77.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((37.50,-161.36) -- (-31.85,-290.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((78.87,-77.72) -- (84.39,-44.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((78.87,-77.72) -- (37.50,-161.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((84.39,-44.06) -- (102.14,-7.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((84.39,-44.06) -- (78.87,-77.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((102.14,-7.70) -- (128.71,4.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((102.14,-7.70) -- (84.39,-44.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((128.71,4.57) -- (141.70,27.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((128.71,4.57) -- (102.14,-7.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((141.70,27.32) -- (172.09,40.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((141.70,27.32) -- (128.71,4.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((172.09,40.78) -- (200.45,116.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((172.09,40.78) -- (141.70,27.32)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((200.45,116.56) -- (201.69,155.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((200.45,116.56) -- (172.09,40.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((201.69,155.37) -- (180.61,193.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((201.69,155.37) -- (200.45,116.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((180.61,193.11) -- (170.84,229.35)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((180.61,193.11) -- (201.69,155.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((170.84,229.35) -- (180.61,193.11)));
endfig;
beginfig(38);
draw_upscrap(1)(1,((-170.92,-287.97)
 .. controls (-163.80,-289.24) and (-103.70,-298.30) .. (-103.70,-298.30)
 .. controls (-103.70,-298.30) and (-56.79,-312.03) .. (-52.34,-309.37)
 .. controls (-47.88,-306.70) and (-12.44,-304.06) .. (-6.76,-298.20)
 .. controls (-1.08,-292.33) and (40.27,-165.65) .. (44.14,-160.07)
 .. controls (48.01,-154.49) and (87.95,-87.19) .. (88.28,-80.35)
 .. controls (88.61,-73.52) and (89.20,-53.37) .. (90.99,-46.24)
 .. controls (92.77,-39.12) and (110.06,-16.16) .. (120.91,-8.02)
 .. controls (131.75,0.12) and (140.46,9.07) .. (143.99,15.03)
 .. controls (147.52,20.99) and (155.70,26.37) .. (161.66,30.41)
 .. controls (167.62,34.46) and (173.90,37.76) .. (179.14,49.41)
 .. controls (184.38,61.05) and (223.34,99.90) .. (218.74,124.29)
 .. controls (214.13,148.66) and (213.68,162.01) .. (205.18,172.87)
 .. controls (196.69,183.72) and (186.09,195.76) .. (184.62,202.67)
 .. controls (183.14,209.59) and (176.60,231.17) .. (175.74,235.89)
),
1,((175.74,235.89)
 .. controls (174.89,240.62) and (161.44,299.20) .. (161.64,303.37)
),
1,((153.63,301.21)
 .. controls (153.63,301.21) and (166.05,236.71) .. (166.50,230.93)
),
1,((166.50,230.93)
 .. controls (166.94,225.14) and (176.26,193.70) .. (178.57,189.27)
 .. controls (180.89,184.83) and (201.02,153.60) .. (198.53,146.51)
 .. controls (196.03,139.43) and (185.48,122.26) .. (183.24,113.00)
 .. controls (181.00,103.73) and (171.30,51.22) .. (161.66,45.55)
 .. controls (152.02,39.88) and (133.44,43.61) .. (130.08,33.34)
 .. controls (126.71,23.05) and (125.87,13.01) .. (117.31,7.29)
 .. controls (108.75,1.57) and (99.90,-2.70) .. (94.34,-13.61)
 .. controls (88.77,-24.51) and (78.03,-38.07) .. (76.94,-45.94)
 .. controls (75.85,-53.81) and (61.52,-112.97) .. (44.87,-129.47)
 .. controls (28.21,-145.97) and (22.68,-171.66) .. (19.91,-176.94)
 .. controls (17.14,-182.21) and (-30.52,-267.53) .. (-37.82,-269.35)
 .. controls (-45.11,-271.16) and (-64.95,-279.23) .. (-65.16,-275.98)
 .. controls (-65.37,-272.73) and (-24.21,-248.37) .. (-24.52,-239.71)
 .. controls (-24.83,-231.04) and (-11.33,-144.10) .. (-10.94,-135.83)
 .. controls (-10.55,-127.55) and (5.84,-103.76) .. (5.80,-94.56)
 .. controls (5.76,-85.44) and (5.79,-75.06) .. (3.89,-66.78)
),
1,((-28.21,-63.50)
 .. controls (-28.21,-63.50) and (-27.10,-88.05) .. (-27.77,-94.53)
 .. controls (-28.43,-101.00) and (-21.79,-129.19) .. (-22.86,-136.34)
 .. controls (-23.92,-143.50) and (-35.28,-215.76) .. (-42.78,-229.46)
 .. controls (-50.28,-243.16) and (-77.98,-249.77) .. (-93.15,-250.43)
 .. controls (-108.32,-251.09) and (-163.94,-263.26) .. (-168.24,-263.26)
),
1,((-168.24,-263.26)
 .. controls (-172.53,-263.24) and (-209.30,-262.44) .. (-213.09,-261.55)
),
1,((-211.18,-287.93)
 .. controls (-211.18,-287.93) and (-178.02,-286.65) .. (-170.92,-287.97)
));
draw_downscrap;
endfig;
beginfig(39);
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-168.24,-263.26)
 .. controls (-172.53,-263.24) and (-209.30,-262.44) .. (-213.09,-261.55)
));
ATTR__id := "amont-marneux_sp1_l1d";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-28.21,-63.50)
 .. controls (-28.21,-63.50) and (-27.10,-88.05) .. (-27.77,-94.53)
 .. controls (-28.43,-101.00) and (-21.79,-129.19) .. (-22.86,-136.34)
 .. controls (-23.92,-143.50) and (-35.28,-215.76) .. (-42.78,-229.46)
 .. controls (-50.28,-243.16) and (-77.98,-249.77) .. (-93.15,-250.43)
 .. controls (-108.32,-251.09) and (-163.94,-263.26) .. (-168.24,-263.26)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_presumed(((175.74,235.89)
 .. controls (174.89,240.62) and (161.44,299.20) .. (161.64,303.37)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-168.52,-275.76)
 -- (-133.19,-274.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-170.92,-287.97)
 .. controls (-163.80,-289.24) and (-103.70,-298.30) .. (-103.70,-298.30)
 .. controls (-103.70,-298.30) and (-56.79,-312.03) .. (-52.34,-309.37)
 .. controls (-47.88,-306.70) and (-12.44,-304.06) .. (-6.76,-298.20)
 .. controls (-1.08,-292.33) and (40.27,-165.65) .. (44.14,-160.07)
 .. controls (48.01,-154.49) and (87.95,-87.19) .. (88.28,-80.35)
 .. controls (88.61,-73.52) and (89.20,-53.37) .. (90.99,-46.24)
 .. controls (92.77,-39.12) and (110.06,-16.16) .. (120.91,-8.02)
 .. controls (131.75,0.12) and (140.46,9.07) .. (143.99,15.03)
 .. controls (147.52,20.99) and (155.70,26.37) .. (161.66,30.41)
 .. controls (167.62,34.46) and (173.90,37.76) .. (179.14,49.41)
 .. controls (184.38,61.05) and (223.34,99.90) .. (218.74,124.29)
 .. controls (214.13,148.66) and (213.68,162.01) .. (205.18,172.87)
 .. controls (196.69,183.72) and (186.09,195.76) .. (184.62,202.67)
 .. controls (183.14,209.59) and (176.60,231.17) .. (175.74,235.89)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-211.18,-287.93)
 .. controls (-211.18,-287.93) and (-178.02,-286.65) .. (-170.92,-287.97)
));
ATTR__id := "amont-marneux_sp1_l1g";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((166.50,230.93)
 .. controls (166.94,225.14) and (176.26,193.70) .. (178.57,189.27)
 .. controls (180.89,184.83) and (201.02,153.60) .. (198.53,146.51)
 .. controls (196.03,139.43) and (185.48,122.26) .. (183.24,113.00)
 .. controls (181.00,103.73) and (171.30,51.22) .. (161.66,45.55)
 .. controls (152.02,39.88) and (133.44,43.61) .. (130.08,33.34)
 .. controls (126.71,23.05) and (125.87,13.01) .. (117.31,7.29)
 .. controls (108.75,1.57) and (99.90,-2.70) .. (94.34,-13.61)
 .. controls (88.77,-24.51) and (78.03,-38.07) .. (76.94,-45.94)
 .. controls (75.85,-53.81) and (61.52,-112.97) .. (44.87,-129.47)
 .. controls (28.21,-145.97) and (22.68,-171.66) .. (19.91,-176.94)
 .. controls (17.14,-182.21) and (-30.52,-267.53) .. (-37.82,-269.35)
 .. controls (-45.11,-271.16) and (-64.95,-279.23) .. (-65.16,-275.98)
 .. controls (-65.37,-272.73) and (-24.21,-248.37) .. (-24.52,-239.71)
 .. controls (-24.83,-231.04) and (-11.33,-144.10) .. (-10.94,-135.83)
 .. controls (-10.55,-127.55) and (5.84,-103.76) .. (5.80,-94.56)
 .. controls (5.76,-85.44) and (5.79,-75.06) .. (3.89,-66.78)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_presumed(((153.63,301.21)
 .. controls (153.63,301.21) and (166.05,236.71) .. (166.50,230.93)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((170.84,229.35),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((180.61,193.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((201.69,155.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((200.45,116.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((172.09,40.78),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((141.70,27.32),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((128.71,4.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((102.14,-7.70),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((84.39,-44.06),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((78.87,-77.72),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((37.50,-161.36),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-31.85,-290.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-56.44,-274.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-102.65,-295.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-28.17,-240.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-18.08,-136.35),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-16.58,-75.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-20.77,-44.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-16.58,-75.77),1,0,"");
endfig;
beginfig(40);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((-163.945,-263.258),(-168.24,-263.26),(-172.536,-263.261),btex \thwallaltitude \thfb\char45 \char56 \char51 \mainfont{} etex);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((176.601,231.167),(175.74,235.89),(174.888,240.617),btex \thwallaltitude \thfb\char45 \char56 \char51 \mainfont{} etex);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char105 \char109 \char112 \char46 \mainfont{} etex,(158.76,317.93),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char51 \mainfont{} etex,(-69.12,-321.15),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char51 \mainfont{} etex,(-133.19,-311.99),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char63 \mainfont{} etex,(-229.56,-273.16),0.0,p_label_mode_label);
ATTR__height := -1;
drawoptions();
l_label(btex \thlabel \thnormalsize \thfb\char80 {}\char108 {}\char97 {}\char102 {}\char111 {}\char110 {}\char100 {}\ \char100 {}\char101 {}\ \char99 {}\char97 {}\char108 {}\char99 {}\char105 {}\char116 {}\char101 {}\mainfont{} etex,((-62.49,-218.61)
 .. controls (-55.69,-212.12) and (-41.95,-87.99) .. (-41.95,-87.99)
));
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \char53 \mainfont{} etex, (170.84, 229.35), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \char52 \mainfont{} etex, (180.61, 193.11), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \char51 \mainfont{} etex, (201.69, 155.37), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \char50 \mainfont{} etex, (200.45, 116.56), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \char49 \mainfont{} etex, (172.09, 40.78), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \char48 \mainfont{} etex, (141.70, 27.32), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char57 \mainfont{} etex, (128.71, 4.57), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char56 \mainfont{} etex, (102.14, -7.70), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char55 \mainfont{} etex, (84.39, -44.06), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char54 \mainfont{} etex, (78.87, -77.72), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char53 \mainfont{} etex, (37.50, -161.36), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char52 \mainfont{} etex, (-31.85, -290.60), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char51 \mainfont{} etex, (-56.44, -274.62), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char80 \char84 \char82 \char49 \char48 \mainfont{} etex, (-102.65, -295.47), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char49 \mainfont{} etex, (-28.17, -240.80), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \char48 \mainfont{} etex, (-18.08, -136.35), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char57 \char57 \mainfont{} etex, (-16.58, -75.77), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char57 \char56 \mainfont{} etex, (-20.77, -44.29), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char57 \char57 \mainfont{} etex, (-16.58, -75.77), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "0-100_sp2@Master";
ATTR__scrap := "0-100_sp2";
beginfig(41);
current_src := "datas/0-100/0-100_p.th2 [628]";
string area_border[];
area_border[1] := "l247-1030-1128";
drawoptions();
a_debris(buildcycle(((162.98,246.62)
 -- (140.47,233.65)
 -- (129.29,200.54)
 -- (103.36,195.48)
 -- (116.27,168.46)
 -- (149.17,177.06)
 -- (189.41,213.50)
 -- (213.90,241.40)
 -- (194.25,249.36)
 -- cycle
)));
current_src := "datas/0-100/0-100_p.th2 [430]";
string area_border[];
area_border[1] := "l142-677-764";
drawoptions();
a_clay(buildcycle(((-151.96,-54.86)
 .. controls (-151.96,-54.86) and (-187.71,-63.07) .. (-188.62,-63.25)
 .. controls (-189.53,-63.44) and (-203.60,-70.48) .. (-207.35,-73.70)
 .. controls (-211.09,-76.91) and (-224.33,-86.01) .. (-219.29,-94.12)
 .. controls (-215.07,-100.91) and (-214.44,-111.45) .. (-207.81,-114.22)
 .. controls (-201.19,-116.99) and (-191.00,-110.69) .. (-182.13,-103.66)
 .. controls (-173.26,-96.63) and (-170.73,-90.43) .. (-159.87,-88.91)
 .. controls (-148.55,-87.32) and (-98.30,-141.20) .. (-86.85,-127.53)
 .. controls (-79.44,-118.70) and (-94.98,-108.67) .. (-94.98,-108.67)
 .. controls (-94.98,-108.67) and (-141.91,-93.57) .. (-141.34,-87.56)
 .. controls (-140.92,-83.10) and (-132.10,-72.71) .. (-130.55,-68.50)
 .. controls (-129.01,-64.29) and (-125.06,-61.77) .. (-130.77,-58.58)
 .. controls (-136.47,-55.39) and (-151.96,-54.86) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_floormeander(((89.32,174.49)
 .. controls (89.32,174.49) and (72.09,152.31) .. (59.88,145.91)
 .. controls (47.65,139.49) and (18.91,106.78) .. (14.51,99.32)
 .. controls (10.10,91.87) and (-20.21,36.03) .. (-22.47,31.18)
));
ATTR__height := -1;
drawoptions();
l_pit(((165.99,193.88)
 .. controls (165.99,193.88) and (177.10,190.87) .. (179.64,201.58)
));
ATTR__height := -1;
drawoptions();
l_pit(((-124.46,-68.34)
 .. controls (-116.66,-55.85) and (-132.05,-52.22) .. (-132.05,-52.22)
));
drawoptions();
p_blocks((14.50,113.74),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((93.54,177.91)
 -- (98.87,166.84)
 -- (107.60,170.91)
 -- (100.16,185.03)
 -- cycle
));
ATTR__id := "l137-930-1039";
ATTR__height := -1;
drawoptions();
l_rockedge(((100.16,185.03)
 -- (104.60,183.46)
 -- (111.73,172.52)
 -- (107.60,170.91)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockedge(((-65.10,-18.65)
 -- (-67.08,-27.11)
 -- (-59.38,-26.12)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-65.10,-18.65)
 -- (-61.01,-17.71)
 -- (-58.53,-22.55)
 -- (-59.38,-26.12)
));
ATTR__height := -1;
drawoptions();
l_pit(((47.86,-186.02)
 .. controls (44.92,-186.34) and (43.83,-190.58) .. (43.95,-193.06)
 .. controls (44.06,-195.55) and (45.07,-198.07) .. (42.21,-201.55)
 .. controls (39.35,-205.03) and (30.66,-197.88) .. (28.02,-196.41)
 .. controls (25.38,-194.93) and (11.05,-207.59) .. (11.05,-207.59)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-27.83,-126.67)
 -- (-19.58,-123.45)
 -- (-11.34,-130.13)
 -- (-15.99,-133.52)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-27.83,-126.67)
 -- (-26.80,-123.79)
 -- (-18.99,-120.32)
 -- (-19.58,-123.45)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-11.54,-124.72)
 -- (-11.34,-130.13)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-18.99,-120.32)
 -- (-11.54,-124.72)
));
ATTR__height := -1;
drawoptions();
l_contour(((-102.89,-13.27)
 .. controls (-102.89,-13.27) and (-84.95,-9.85) .. (-80.27,-20.19)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-104.91,-17.89)
 .. controls (-104.91,-17.89) and (-89.45,-14.12) .. (-83.33,-22.51)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-106.49,-22.76)
 .. controls (-106.49,-22.76) and (-97.65,-16.43) .. (-89.75,-25.12)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-108.31,-27.61)
 .. controls (-108.31,-27.61) and (-96.78,-21.86) .. (-90.40,-29.36)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-107.85,-31.91)
 .. controls (-107.85,-31.91) and (-100.34,-25.74) .. (-91.50,-33.57)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-105.33,-35.62)
 .. controls (-105.33,-35.62) and (-98.81,-31.43) .. (-91.90,-37.37)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-101.52,-40.74)
 .. controls (-101.52,-40.74) and (-99.50,-36.34) .. (-93.61,-40.21)
),-1);
ATTR__height := -1;
drawoptions();
l_rockedge(((-93.00,-46.31)
 -- (-92.44,-53.30)
 -- (-86.75,-51.99)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-93.00,-46.31)
 -- (-87.68,-24.09)
 -- (-68.79,-29.73)
 -- (-69.25,-20.70)
 -- (-87.68,-24.09)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-86.75,-51.99)
 -- (-68.79,-29.73)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-42.00,-107.10)
 -- (-46.85,-114.54)
 -- (-36.71,-124.01)
 -- (-23.52,-121.02)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-42.00,-107.10)
 -- (-42.33,-104.61)
 -- (-23.31,-116.52)
 -- (-23.52,-121.02)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-46.85,-114.54)
 -- (-47.36,-111.13)
 -- (-42.33,-104.61)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.70,-195.52) -- (21.36,-228.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.70,-195.52) -- (2.91,-145.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-103.88,-243.52) -- (-80.06,-229.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-80.06,-229.01) -- (-103.88,-243.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-80.06,-229.01) -- (-55.07,-212.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-55.07,-212.19) -- (-80.06,-229.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-55.07,-212.19) -- (2.91,-145.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.91,-145.40) -- (14.70,-195.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.91,-145.40) -- (-55.07,-212.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2.91,-145.40) -- (-81.60,-133.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-81.60,-133.14) -- (2.91,-145.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-81.60,-133.14) -- (-158.50,-80.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-230.11,-108.78) -- (-158.50,-80.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-158.50,-80.37) -- (-81.60,-133.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-158.50,-80.37) -- (-230.11,-108.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-158.50,-80.37) -- (-139.51,-83.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-139.51,-83.46) -- (-158.50,-80.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-139.51,-83.46) -- (-121.48,-52.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-121.48,-52.94) -- (-139.51,-83.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-121.48,-52.94) -- (-91.26,-53.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-91.26,-53.13) -- (-121.48,-52.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-91.26,-53.13) -- (-94.10,-2.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-94.10,-2.89) -- (-91.26,-53.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-94.10,-2.89) -- (-51.54,-20.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((45.15,8.39) -- (-49.54,-11.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-49.54,-11.63) -- (45.15,8.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-49.54,-11.63) -- (-51.54,-20.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.54,-20.75) -- (-94.10,-2.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.54,-20.75) -- (-49.54,-11.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-51.54,-20.75) -- (-24.57,9.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((27.55,23.43) -- (-24.57,9.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-24.57,9.04) -- (-51.54,-20.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-24.57,9.04) -- (27.55,23.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-24.57,9.04) -- (-35.38,12.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-35.38,12.40) -- (-24.57,9.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-35.38,12.40) -- (16.63,105.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((16.63,105.23) -- (-35.38,12.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((16.63,105.23) -- (61.32,148.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((61.32,148.75) -- (16.63,105.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((61.32,148.75) -- (74.66,155.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((74.66,155.47) -- (61.32,148.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((74.66,155.47) -- (96.72,188.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((96.72,188.11) -- (74.66,155.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((96.72,188.11) -- (126.73,171.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((126.73,171.02) -- (96.72,188.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((126.73,171.02) -- (165.92,200.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((165.92,200.60) -- (126.73,171.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((165.92,200.60) -- (174.07,197.83)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((174.07,197.83) -- (165.92,200.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((174.07,197.83) -- (164.74,184.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((232.54,236.20) -- (164.74,184.48)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((164.74,184.48) -- (174.07,197.83)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((164.74,184.48) -- (232.54,236.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((164.74,184.48) -- (177.50,152.96)));
endfig;
beginfig(42);
draw_upscrap(1)(1,((40.32,136.89)
 .. controls (40.32,136.89) and (12.85,117.20) .. (12.19,112.50)
 .. controls (11.52,107.80) and (-32.77,22.12) .. (-33.30,21.09)
 .. controls (-42.46,3.42) and (-27.59,8.36) .. (-33.81,-0.20)
 .. controls (-45.39,-16.16) and (-50.48,-9.65) .. (-50.48,-9.65)
 .. controls (-50.48,-9.65) and (-56.62,-1.70) .. (-77.28,0.38)
 .. controls (-98.11,2.46) and (-95.78,-0.79) .. (-100.59,-7.31)
 .. controls (-105.39,-13.83) and (-112.10,-30.82) .. (-108.04,-35.50)
 .. controls (-103.98,-40.18) and (-93.34,-53.26) .. (-99.91,-54.10)
 .. controls (-106.48,-54.94) and (-114.50,-52.79) .. (-121.48,-52.94)
 .. controls (-126.81,-53.05) and (-152.05,-51.70) .. (-163.85,-54.05)
 .. controls (-175.68,-56.40) and (-206.24,-64.27) .. (-212.62,-70.75)
 .. controls (-218.99,-77.23) and (-236.40,-104.16) .. (-234.01,-111.02)
 .. controls (-231.62,-117.88) and (-213.12,-122.08) .. (-201.18,-121.72)
 .. controls (-189.25,-121.35) and (-170.38,-87.75) .. (-159.05,-90.53)
 .. controls (-147.68,-93.31) and (-138.07,-104.60) .. (-128.72,-111.80)
 .. controls (-119.36,-119.01) and (-84.03,-139.61) .. (-82.32,-141.49)
 .. controls (-80.60,-143.38) and (-30.39,-172.24) .. (-39.36,-181.28)
 .. controls (-48.34,-190.31) and (-59.55,-186.23) .. (-64.98,-189.32)
 .. controls (-81.86,-198.94) and (-102.10,-218.56) .. (-102.10,-218.56)
 .. controls (-102.10,-218.56) and (-113.35,-252.27) .. (-94.38,-246.61)
 .. controls (-75.39,-240.95) and (-50.77,-223.96) .. (-48.62,-221.13)
 .. controls (-46.47,-218.30) and (-30.13,-210.50) .. (-26.64,-207.96)
 .. controls (-23.15,-205.43) and (-9.23,-176.84) .. (-1.51,-186.03)
 .. controls (6.19,-195.20) and (7.79,-199.77) .. (7.79,-199.77)
),
1,((7.79,-199.77)
 .. controls (7.79,-199.77) and (19.96,-224.89) .. (32.98,-221.20)
 .. controls (45.99,-217.51) and (56.18,-216.38) .. (54.38,-206.38)
 .. controls (52.58,-196.38) and (43.62,-175.01) .. (42.57,-173.38)
),
1,((42.57,-173.38)
 .. controls (36.64,-164.77) and (21.80,-119.50) .. (1.04,-105.92)
 .. controls (-19.70,-92.36) and (-57.10,-102.79) .. (-64.49,-101.99)
 .. controls (-71.88,-101.19) and (-104.71,-104.82) .. (-122.85,-97.43)
 .. controls (-140.99,-90.03) and (-139.71,-85.87) .. (-138.80,-85.69)
 .. controls (-137.89,-85.51) and (-121.67,-66.44) .. (-119.92,-62.69)
 .. controls (-118.16,-58.94) and (-107.36,-69.54) .. (-100.34,-68.71)
 .. controls (-93.33,-67.89) and (-92.58,-61.40) .. (-89.43,-56.36)
 .. controls (-86.27,-51.33) and (-55.70,-24.49) .. (-50.67,-22.92)
 .. controls (-45.63,-21.35) and (-30.95,-11.00) .. (-30.95,-11.00)
),
1,((-30.95,-11.00)
 -- (36.83,3.65)
),
1,((35.46,8.00)
 -- (-30.90,-4.92)
),
1,reverse ((-17.05,6.26)
 .. controls (-17.05,6.26) and (-19.76,5.71) .. (-21.96,2.19)
 .. controls (-24.18,-1.39) and (-35.41,-5.56) .. (-30.90,-4.92)
),
1,((-17.05,6.26)
 .. controls (-17.74,6.07) and (27.94,21.00) .. (27.94,21.00)
),
1,((27.46,25.07)
 -- (-16.05,13.41)
),
1,reverse ((44.52,125.21)
 .. controls (44.52,125.21) and (24.93,105.38) .. (22.11,98.07)
 .. controls (19.30,90.76) and (-24.66,22.94) .. (-23.54,17.57)
 .. controls (-22.41,12.14) and (-22.49,10.34) .. (-16.05,13.41)
),
1,reverse ((167.33,154.81)
 .. controls (167.33,154.81) and (169.05,157.89) .. (162.67,171.49)
 .. controls (156.31,185.08) and (160.48,187.15) .. (160.48,187.15)
 .. controls (160.48,187.15) and (169.42,189.68) .. (167.30,192.70)
 .. controls (165.18,195.72) and (166.63,198.12) .. (163.12,195.57)
 .. controls (159.61,193.04) and (130.12,172.13) .. (126.73,171.02)
 .. controls (123.33,169.92) and (105.95,183.63) .. (99.23,179.44)
 .. controls (92.51,175.26) and (77.17,154.99) .. (75.75,153.71)
 .. controls (74.34,152.42) and (44.52,125.21) .. (44.52,125.21)
),
1,((184.28,155.59)
 .. controls (184.28,155.59) and (177.05,164.95) .. (177.71,174.39)
 .. controls (178.37,183.83) and (181.51,188.65) .. (195.95,199.23)
 .. controls (210.40,209.82) and (209.38,207.16) .. (212.71,211.06)
),
1,((212.71,211.06)
 .. controls (212.71,211.06) and (241.19,237.42) .. (234.20,237.29)
 .. controls (227.21,237.17) and (180.30,201.32) .. (178.51,200.97)
 .. controls (176.71,200.62) and (182.74,210.23) .. (188.78,219.17)
 .. controls (194.83,228.12) and (209.47,247.46) .. (193.13,244.68)
 .. controls (176.78,241.89) and (146.35,244.00) .. (144.42,221.50)
 .. controls (142.50,199.02) and (147.05,199.49) .. (135.15,190.80)
 .. controls (123.24,182.11) and (127.39,184.17) .. (127.39,184.17)
 .. controls (127.39,184.17) and (102.97,191.18) .. (96.72,188.11)
 .. controls (90.48,185.03) and (75.56,159.12) .. (71.21,157.52)
 .. controls (66.87,155.92) and (40.32,136.89) .. (40.32,136.89)
));
draw_downscrap;
endfig;
beginfig(43);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((184.28,155.59)
 .. controls (184.28,155.59) and (177.05,164.95) .. (177.71,174.39)
 .. controls (178.37,183.83) and (181.51,188.65) .. (195.95,199.23)
 .. controls (210.40,209.82) and (209.38,207.16) .. (212.71,211.06)
));
ATTR__id := "l100-888-1014";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((167.33,154.81)
 .. controls (167.33,154.81) and (169.05,157.89) .. (162.67,171.49)
 .. controls (156.31,185.08) and (160.48,187.15) .. (160.48,187.15)
 .. controls (160.48,187.15) and (169.42,189.68) .. (167.30,192.70)
 .. controls (165.18,195.72) and (166.63,198.12) .. (163.12,195.57)
 .. controls (159.61,193.04) and (130.12,172.13) .. (126.73,171.02)
 .. controls (123.33,169.92) and (105.95,183.63) .. (99.23,179.44)
 .. controls (92.51,175.26) and (77.17,154.99) .. (75.75,153.71)
 .. controls (74.34,152.42) and (44.52,125.21) .. (44.52,125.21)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((150.86,243.34)
 -- (157.15,223.18)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((44.52,125.21)
 .. controls (44.52,125.21) and (24.93,105.38) .. (22.11,98.07)
 .. controls (19.30,90.76) and (-24.66,22.94) .. (-23.54,17.57)
 .. controls (-22.41,12.14) and (-22.49,10.34) .. (-16.05,13.41)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-235.35,-95.65)
 -- (-214.80,-94.32)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((27.46,25.07)
 -- (-16.05,13.41)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-17.05,6.26)
 .. controls (-17.74,6.07) and (27.94,21.00) .. (27.94,21.00)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-17.05,6.26)
 .. controls (-17.05,6.26) and (-19.76,5.71) .. (-21.96,2.19)
 .. controls (-24.18,-1.39) and (-35.41,-5.56) .. (-30.90,-4.92)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((35.46,8.00)
 -- (-30.90,-4.92)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-30.95,-11.00)
 -- (36.83,3.65)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((42.57,-173.38)
 .. controls (36.64,-164.77) and (21.80,-119.50) .. (1.04,-105.92)
 .. controls (-19.70,-92.36) and (-57.10,-102.79) .. (-64.49,-101.99)
 .. controls (-71.88,-101.19) and (-104.71,-104.82) .. (-122.85,-97.43)
 .. controls (-140.99,-90.03) and (-139.71,-85.87) .. (-138.80,-85.69)
 .. controls (-137.89,-85.51) and (-121.67,-66.44) .. (-119.92,-62.69)
 .. controls (-118.16,-58.94) and (-107.36,-69.54) .. (-100.34,-68.71)
 .. controls (-93.33,-67.89) and (-92.58,-61.40) .. (-89.43,-56.36)
 .. controls (-86.27,-51.33) and (-55.70,-24.49) .. (-50.67,-22.92)
 .. controls (-45.63,-21.35) and (-30.95,-11.00) .. (-30.95,-11.00)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((212.71,211.06)
 .. controls (212.71,211.06) and (241.19,237.42) .. (234.20,237.29)
 .. controls (227.21,237.17) and (180.30,201.32) .. (178.51,200.97)
 .. controls (176.71,200.62) and (182.74,210.23) .. (188.78,219.17)
 .. controls (194.83,228.12) and (209.47,247.46) .. (193.13,244.68)
 .. controls (176.78,241.89) and (146.35,244.00) .. (144.42,221.50)
 .. controls (142.50,199.02) and (147.05,199.49) .. (135.15,190.80)
 .. controls (123.24,182.11) and (127.39,184.17) .. (127.39,184.17)
 .. controls (127.39,184.17) and (102.97,191.18) .. (96.72,188.11)
 .. controls (90.48,185.03) and (75.56,159.12) .. (71.21,157.52)
 .. controls (66.87,155.92) and (40.32,136.89) .. (40.32,136.89)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((40.32,136.89)
 .. controls (40.32,136.89) and (12.85,117.20) .. (12.19,112.50)
 .. controls (11.52,107.80) and (-32.77,22.12) .. (-33.30,21.09)
 .. controls (-42.46,3.42) and (-27.59,8.36) .. (-33.81,-0.20)
 .. controls (-45.39,-16.16) and (-50.48,-9.65) .. (-50.48,-9.65)
 .. controls (-50.48,-9.65) and (-56.62,-1.70) .. (-77.28,0.38)
 .. controls (-98.11,2.46) and (-95.78,-0.79) .. (-100.59,-7.31)
 .. controls (-105.39,-13.83) and (-112.10,-30.82) .. (-108.04,-35.50)
 .. controls (-103.98,-40.18) and (-93.34,-53.26) .. (-99.91,-54.10)
 .. controls (-106.48,-54.94) and (-114.50,-52.79) .. (-121.48,-52.94)
 .. controls (-126.81,-53.05) and (-152.05,-51.70) .. (-163.85,-54.05)
 .. controls (-175.68,-56.40) and (-206.24,-64.27) .. (-212.62,-70.75)
 .. controls (-218.99,-77.23) and (-236.40,-104.16) .. (-234.01,-111.02)
 .. controls (-231.62,-117.88) and (-213.12,-122.08) .. (-201.18,-121.72)
 .. controls (-189.25,-121.35) and (-170.38,-87.75) .. (-159.05,-90.53)
 .. controls (-147.68,-93.31) and (-138.07,-104.60) .. (-128.72,-111.80)
 .. controls (-119.36,-119.01) and (-84.03,-139.61) .. (-82.32,-141.49)
 .. controls (-80.60,-143.38) and (-30.39,-172.24) .. (-39.36,-181.28)
 .. controls (-48.34,-190.31) and (-59.55,-186.23) .. (-64.98,-189.32)
 .. controls (-81.86,-198.94) and (-102.10,-218.56) .. (-102.10,-218.56)
 .. controls (-102.10,-218.56) and (-113.35,-252.27) .. (-94.38,-246.61)
 .. controls (-75.39,-240.95) and (-50.77,-223.96) .. (-48.62,-221.13)
 .. controls (-46.47,-218.30) and (-30.13,-210.50) .. (-26.64,-207.96)
 .. controls (-23.15,-205.43) and (-9.23,-176.84) .. (-1.51,-186.03)
 .. controls (6.19,-195.20) and (7.79,-199.77) .. (7.79,-199.77)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((7.79,-199.77)
 .. controls (7.79,-199.77) and (19.96,-224.89) .. (32.98,-221.20)
 .. controls (45.99,-217.51) and (56.18,-216.38) .. (54.38,-206.38)
 .. controls (52.58,-196.38) and (43.62,-175.01) .. (42.57,-173.38)
));
ATTR__height := -1;
drawoptions();
l_gradient(((-89.65,-8.95)
 .. controls (-89.65,-8.95) and (-98.28,-16.48) .. (-96.59,-45.91)
));
drawoptions();
p_stalactite((-76.73,-215.19),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_stalagmite((-84.78,-233.99),0.0,1.00,(0,0));
drawoptions();
p_stalactite((20.47,-153.67),37.3,0.71,(0,0));
drawoptions();
p_stalactite((218.90,222.92),0.0,0.71,(0,0));
drawoptions();
p_stalactite((26.18,-172.19),331.5,1.00,(0,0));
drawoptions();
p_stalactite((-56.22,-146.75),0.0,1.00,(0,0));
drawoptions();
p_gypsum((-67.51,-200.25),0.0,1.00,(0,0));
drawoptions();
p_gypsum((-95.15,-219.33),0.0,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((164.74,184.48),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((232.54,236.20),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((174.07,197.83),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((165.92,200.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((126.73,171.02),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((96.72,188.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((74.66,155.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((61.32,148.75),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((16.63,105.23),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-35.38,12.40),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-24.57,9.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((27.55,23.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-51.54,-20.75),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-49.54,-11.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((45.15,8.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-94.10,-2.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-91.26,-53.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-121.48,-52.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-139.51,-83.46),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-158.50,-80.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-230.11,-108.78),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-81.60,-133.14),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((2.91,-145.40),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-55.07,-212.19),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-80.06,-229.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-103.88,-243.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((14.70,-195.52),1,0,"");
endfig;
beginfig(44);
drawoptions();
p_label(btex \thlabel\thsmallsize \vtop{\halign{#\hfil\cr\thfb\char80 \char55 \cr\thfb \char80 \char116 \char115 \ \char100 \char117 \ \char99 \char108 \char111 \char119 \char110 \cr}}\mainfont{} etex,(216.06,184.35),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char82 \char50 \mainfont{} etex,(-151.22,-28.80),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((-45.6308,-21.3511),(-30.95,-11.00),(-16.2777,-0.649647),btex \thwallaltitude \thfb\char45 \char55 \char54 \mainfont{} etex);
ATTR__height := -1;
drawoptions();
l_label(btex \thlabel \thnormalsize \thfb\char108 {}\char97 {}\char109 {}\char105 {}\char110 {}\char111 {}\char105 {}\char114 {}\mainfont{} etex,((-145.78,-110.10)
 -- (-97.07,-143.73)
));
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((209.465,247.462),(193.13,244.68),(176.775,241.891),btex \thwallaltitude \thfb\char45 \char55 \char52 \mainfont{} etex);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((-236.403,-104.156),(-234.01,-111.02),(-231.616,-117.878),btex \thwallaltitude \thfb\char45 \char56 \char52 \mainfont{} etex);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char51 \mainfont{} etex, (164.74, 184.48), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char52 \mainfont{} etex, (232.54, 236.20), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char53 \mainfont{} etex, (174.07, 197.83), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char54 \mainfont{} etex, (165.92, 200.60), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char55 \mainfont{} etex, (126.73, 171.02), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char56 \mainfont{} etex, (96.72, 188.11), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char57 \mainfont{} etex, (74.66, 155.47), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char48 \mainfont{} etex, (61.32, 148.75), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char49 \mainfont{} etex, (16.63, 105.23), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char50 \mainfont{} etex, (-35.38, 12.40), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char51 \mainfont{} etex, (-24.57, 9.04), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char52 \mainfont{} etex, (27.55, 23.43), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char53 \mainfont{} etex, (-51.54, -20.75), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char54 \mainfont{} etex, (-49.54, -11.63), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char55 \mainfont{} etex, (45.15, 8.39), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char56 \mainfont{} etex, (-94.10, -2.89), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char57 \mainfont{} etex, (-91.26, -53.13), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char48 \mainfont{} etex, (-121.48, -52.94), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char49 \mainfont{} etex, (-139.51, -83.46), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char50 \mainfont{} etex, (-158.50, -80.37), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char51 \mainfont{} etex, (-230.11, -108.78), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char52 \mainfont{} etex, (-81.60, -133.14), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char53 \mainfont{} etex, (2.91, -145.40), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char54 \mainfont{} etex, (-55.07, -212.19), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char55 \mainfont{} etex, (-80.06, -229.01), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char56 \mainfont{} etex, (-103.88, -243.52), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char57 \mainfont{} etex, (14.70, -195.52), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "sp_cav_pullover_3@Master";
ATTR__scrap := "sp_cav_pullover_3";
beginfig(45);
ATTR__height := -1;
drawoptions();
l_pit(((-46.25,25.27)
 .. controls (-45.94,36.16) and (-44.71,38.11) .. (-53.08,41.46)
 .. controls (-61.39,44.79) and (-70.19,46.65) .. (-78.65,47.44)
 .. controls (-88.74,48.37) and (-98.36,49.88) .. (-98.36,49.88)
));
ATTR__height := -1;
drawoptions();
l_pit(((-98.36,49.88)
 .. controls (-98.36,49.88) and (-130.00,55.38) .. (-139.07,54.99)
 .. controls (-146.38,54.67) and (-158.72,52.16) .. (-158.79,37.61)
 .. controls (-158.86,23.39) and (-148.87,18.08) .. (-136.64,15.33)
 .. controls (-118.79,11.30) and (-117.05,-9.90) .. (-119.08,-14.85)
 .. controls (-121.21,-20.04) and (-137.67,-30.95) .. (-143.24,-36.26)
 .. controls (-148.83,-41.60) and (-126.25,-49.39) .. (-122.98,-50.50)
 .. controls (-95.66,-59.73) and (-98.92,-54.09) .. (-92.16,-47.45)
 .. controls (-89.98,-45.31) and (-87.47,-43.18) .. (-83.72,-27.47)
 .. controls (-80.03,-12.00) and (-84.54,-16.01) .. (-79.44,-10.88)
 .. controls (-74.34,-5.75) and (-68.32,-7.48) .. (-58.76,-1.21)
 .. controls (-48.70,5.39) and (-46.52,14.39) .. (-46.25,25.27)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-221.33,56.69)
 -- (-233.66,45.26)
 -- (-226.80,38.71)
 -- (-209.85,40.55)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-221.33,56.69)
 -- (-214.61,58.38)
 -- (-208.00,48.00)
 -- (-209.85,40.55)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-233.66,45.26)
 -- (-225.57,58.05)
 -- (-214.61,58.38)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-192.47,41.24)
 -- (-186.24,31.97)
 -- (-174.42,34.35)
 -- (-179.88,44.93)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-192.47,41.24)
 -- (-191.26,49.18)
 -- (-181.12,50.23)
 -- (-179.88,44.93)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-181.12,50.23)
 -- (-173.53,43.90)
 -- (-174.42,34.35)
));
ATTR__height := -1;
drawoptions();
l_pit(((161.51,35.91)
 .. controls (161.51,35.91) and (130.32,30.78) .. (128.64,30.12)
 .. controls (126.12,29.12) and (89.95,23.94) .. (108.99,18.51)
 .. controls (128.03,13.08) and (134.63,-3.63) .. (161.84,-3.41)
 .. controls (189.06,-3.19) and (198.21,-0.29) .. (223.70,0.88)
 .. controls (243.97,1.81) and (257.05,-1.35) .. (241.24,14.36)
 .. controls (232.66,22.89) and (214.28,24.51) .. (202.07,28.04)
 .. controls (189.87,31.58) and (161.51,35.91) .. cycle
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-41.58,24.33)
 .. controls (-26.62,21.95) and (3.01,29.20) .. (13.98,28.19)
 .. controls (24.95,27.17) and (64.00,30.61) .. (64.00,30.61)
));
drawoptions();
p_blocks((-121.43,30.92),357.0,1.00,(0,0));
drawoptions();
p_blocks((-75.09,13.04),297.0,0.71,(0,0));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-121.51,5.53) -- (-91.01,29.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-121.51,5.53) -- (-115.39,-25.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-118.64,-24.27) -- (-147.40,-43.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-118.64,-24.27) -- (-53.28,45.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-53.28,45.11) -- (-118.64,-24.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-53.28,45.11) -- (45.61,27.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((45.61,27.38) -- (-53.28,45.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((45.61,27.38) -- (122.04,31.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((122.04,31.39) -- (45.61,27.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((122.04,31.39) -- (262.39,-1.01)));
endfig;
beginfig(46);
draw_upscrap(1)(1,((264.37,12.94)
 .. controls (264.37,12.94) and (213.43,26.61) .. (203.74,29.98)
 .. controls (152.44,47.82) and (156.83,36.58) .. (121.36,32.72)
 .. controls (96.90,30.05) and (70.49,34.78) .. (49.63,44.14)
 .. controls (38.02,49.34) and (13.45,44.66) .. (-10.85,44.54)
 .. controls (-32.94,44.42) and (-47.48,45.64) .. (-54.64,46.22)
 .. controls (-61.76,46.80) and (-240.01,74.53) .. (-255.12,58.06)
 .. controls (-270.24,41.59) and (-274.03,45.90) .. (-259.04,35.01)
 .. controls (-244.04,24.11) and (-187.85,31.40) .. (-170.41,19.37)
 .. controls (-152.90,7.28) and (-123.94,17.37) .. (-122.25,-2.04)
 .. controls (-120.55,-21.48) and (-139.38,-29.24) .. (-143.37,-31.48)
),
1,((-143.37,-31.48)
 .. controls (-143.37,-31.48) and (-161.02,-42.85) .. (-128.09,-52.67)
 .. controls (-95.16,-62.50) and (-92.59,-61.29) .. (-89.97,-55.77)
),
1,reverse ((-53.30,-4.66)
 .. controls (-53.30,-4.66) and (-81.80,-8.07) .. (-76.29,-17.82)
 .. controls (-74.70,-20.62) and (-75.90,-22.41) .. (-82.71,-40.67)
 .. controls (-84.01,-44.13) and (-87.01,-52.10) .. (-89.97,-55.77)
),
1,((-53.30,-4.66)
 .. controls (-53.30,-4.66) and (-12.57,-0.74) .. (-0.58,2.18)
 .. controls (17.64,6.62) and (41.92,15.52) .. (50.42,19.37)
 .. controls (54.50,21.22) and (81.11,26.86) .. (89.38,26.00)
 .. controls (97.64,25.14) and (107.76,16.12) .. (108.41,15.85)
 .. controls (137.46,3.64) and (135.16,-2.09) .. (150.31,-4.63)
 .. controls (165.48,-7.18) and (245.36,2.35) .. (262.31,-1.00)
));
draw_downscrap;
endfig;
beginfig(47);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((264.37,12.94)
 .. controls (264.37,12.94) and (213.43,26.61) .. (203.74,29.98)
 .. controls (152.44,47.82) and (156.83,36.58) .. (121.36,32.72)
 .. controls (96.90,30.05) and (70.49,34.78) .. (49.63,44.14)
 .. controls (38.02,49.34) and (13.45,44.66) .. (-10.85,44.54)
 .. controls (-32.94,44.42) and (-47.48,45.64) .. (-54.64,46.22)
 .. controls (-61.76,46.80) and (-240.01,74.53) .. (-255.12,58.06)
 .. controls (-270.24,41.59) and (-274.03,45.90) .. (-259.04,35.01)
 .. controls (-244.04,24.11) and (-187.85,31.40) .. (-170.41,19.37)
 .. controls (-152.90,7.28) and (-123.94,17.37) .. (-122.25,-2.04)
 .. controls (-120.55,-21.48) and (-139.38,-29.24) .. (-143.37,-31.48)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-128.71,-44.68)
 .. controls (-128.71,-44.68) and (-124.27,-30.41) .. (-114.86,-23.71)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-143.37,-31.48)
 .. controls (-143.37,-31.48) and (-161.02,-42.85) .. (-128.09,-52.67)
 .. controls (-95.16,-62.50) and (-92.59,-61.29) .. (-89.97,-55.77)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((53.47,31.13)
 -- (100.73,28.58)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((203.08,12.04)
 .. controls (203.08,12.04) and (211.68,-10.19) .. (223.01,-17.97)
 .. controls (234.34,-25.75) and (259.30,-31.11) .. (274.43,-34.83)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-53.30,-4.66)
 .. controls (-53.30,-4.66) and (-81.80,-8.07) .. (-76.29,-17.82)
 .. controls (-74.70,-20.62) and (-75.90,-22.41) .. (-82.71,-40.67)
 .. controls (-84.01,-44.13) and (-87.01,-52.10) .. (-89.97,-55.77)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-53.30,-4.66)
 .. controls (-53.30,-4.66) and (-12.57,-0.74) .. (-0.58,2.18)
 .. controls (17.64,6.62) and (41.92,15.52) .. (50.42,19.37)
 .. controls (54.50,21.22) and (81.11,26.86) .. (89.38,26.00)
 .. controls (97.64,25.14) and (107.76,16.12) .. (108.41,15.85)
 .. controls (137.46,3.64) and (135.16,-2.09) .. (150.31,-4.63)
 .. controls (165.48,-7.18) and (245.36,2.35) .. (262.31,-1.00)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((122.04,31.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((45.61,27.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-53.28,45.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-118.64,-24.27),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-121.51,5.53),1,0,"");
endfig;
beginfig(48);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char80 \char52 \char48 \mainfont{} etex,(-44.53,-37.46),0.0,p_label_mode_label);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char48 \mainfont{} etex, (122.04, 31.39), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char49 \mainfont{} etex, (45.61, 27.38), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char50 \mainfont{} etex, (-53.28, 45.11), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char51 \mainfont{} etex, (-118.64, -24.27), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char53 \mainfont{} etex, (-121.51, 5.53), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "sp_cav_pullover_2@Master";
ATTR__scrap := "sp_cav_pullover_2";
beginfig(49);
ATTR__height := -1;
drawoptions();
l_rockborder(((232.30,-34.89)
 -- (231.50,-42.53)
 -- (236.63,-45.11)
 -- (241.53,-41.62)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((232.30,-34.89)
 -- (238.61,-35.30)
 -- (244.38,-39.57)
 -- (241.53,-41.62)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((236.63,-45.11)
 -- (245.66,-45.45)
 -- (244.38,-39.57)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-82.95,-18.11)
 -- (-95.25,-32.36)
 -- (-84.85,-46.62)
 -- (-56.86,-46.56)
 -- (-50.84,-32.64)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-82.95,-18.11)
 -- (-72.75,-12.43)
 -- (-42.55,-24.43)
 -- (-50.84,-32.64)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-56.86,-46.56)
 -- (-41.55,-42.99)
 -- (-42.55,-24.43)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((57.44,-15.24)
 -- (45.90,-29.70)
 .. controls (45.90,-29.70) and (71.24,-45.91) .. (72.14,-45.95)
 .. controls (73.04,-45.99) and (103.75,-46.03) .. (103.75,-46.03)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((57.44,-15.24)
 -- (72.54,-12.46)
 -- (94.59,-29.57)
 -- (103.75,-46.03)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((121.14,-43.43)
 -- (128.66,-23.42)
 -- (145.98,-26.96)
 -- (144.92,-42.97)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((128.66,-23.42)
 -- (123.94,-3.65)
 -- (143.60,-3.43)
 -- (145.98,-26.96)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((123.94,-3.65)
 -- (119.24,-16.69)
 -- (121.14,-43.43)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((164.98,-28.63)
 -- (155.11,-45.30)
 -- (172.24,-50.62)
 -- (175.65,-41.44)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((164.98,-28.63)
 -- (160.45,-22.54)
 -- (154.34,-32.15)
 -- (155.11,-45.30)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((160.45,-22.54)
 -- (172.19,-27.37)
 -- (175.65,-41.44)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-260.22,71.00)
 -- (-260.98,67.76)
 -- (-255.63,64.67)
 -- (-250.36,64.87)
 -- (-259.16,70.45)
 -- (-254.13,69.44)
 -- (-249.13,67.07)
 -- (-250.36,64.87)
));
ATTR__height := -1;
drawoptions();
l_pit(((-242.04,47.71)
 .. controls (-280.65,51.84) and (-249.85,33.05) .. (-249.85,33.05)
));
ATTR__height := -1;
drawoptions();
l_pit(((-187.95,9.41)
 .. controls (-219.24,27.29) and (-204.46,-3.64) .. (-204.46,-3.64)
));
ATTR__height := -1;
drawoptions();
l_pit(((-160.65,-8.04)
 .. controls (-175.78,-12.97) and (-163.87,-15.12) .. (-163.79,-23.64)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-160.27,-10.78) -- (-178.68,-27.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-160.27,-10.78) -- (-132.59,-28.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-178.68,-27.74) -- (-203.41,14.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-178.68,-27.74) -- (-160.27,-10.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-203.41,14.15) -- (-244.65,36.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-203.41,14.15) -- (-178.68,-27.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-244.65,36.58) -- (-264.79,63.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-244.65,36.58) -- (-203.41,14.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-264.79,63.44) -- (-244.65,36.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-132.59,-28.38) -- (-160.27,-10.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-132.59,-28.38) -- (-73.57,-26.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-193.37,-16.15) -- (-151.70,42.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-193.37,-16.15) -- (-245.56,-15.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-245.56,-15.74) -- (-183.69,-31.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-245.56,-15.74) -- (-193.37,-16.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-245.56,-15.74) -- (-356.06,-3.30)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-183.69,-31.36) -- (-123.89,-24.88)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-183.69,-31.36) -- (-245.56,-15.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-123.89,-24.88) -- (-5.57,-30.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-123.89,-24.88) -- (-183.69,-31.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-249.18,62.87) -- (-151.70,42.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-151.70,42.60) -- (-249.18,62.87)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-151.70,42.60) -- (-193.37,-16.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-73.57,-26.57) -- (-132.59,-28.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-73.57,-26.57) -- (-5.57,-30.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-5.57,-30.31) -- (-73.57,-26.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-5.57,-30.31) -- (74.17,-9.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-5.57,-30.31) -- (-123.89,-24.88)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((74.17,-9.13) -- (5.80,-24.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((74.17,-9.13) -- (102.50,3.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((74.17,-9.13) -- (124.09,-13.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((74.17,-9.13) -- (-5.57,-30.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((124.09,-13.18) -- (136.75,-14.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((124.09,-13.18) -- (74.17,-9.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((136.75,-14.59) -- (187.35,-36.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((136.75,-14.59) -- (124.09,-13.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((187.35,-36.22) -- (237.06,-35.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((187.35,-36.22) -- (136.75,-14.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((237.06,-35.31) -- (187.35,-36.22)));
endfig;
beginfig(50);
draw_upscrap(1)(1,((241.31,-46.18)
 .. controls (241.31,-46.18) and (233.79,-47.86) .. (229.90,-48.40)
 .. controls (225.98,-48.94) and (211.18,-41.90) .. (191.17,-46.45)
 .. controls (172.78,-50.62) and (170.10,-62.42) .. (159.70,-62.05)
 .. controls (144.03,-61.50) and (139.08,-60.21) .. (135.69,-58.60)
 .. controls (128.30,-55.07) and (118.70,-50.55) .. (103.33,-52.34)
 .. controls (87.92,-54.12) and (75.27,-53.79) .. (69.93,-51.06)
 .. controls (64.61,-48.34) and (4.03,-41.60) .. (-6.26,-44.31)
 .. controls (-16.50,-47.02) and (-54.71,-48.91) .. (-63.34,-55.50)
 .. controls (-71.98,-62.08) and (-139.58,-55.91) .. (-144.74,-54.81)
 .. controls (-149.90,-53.71) and (-169.21,-50.42) .. (-180.52,-50.64)
 .. controls (-191.86,-50.86) and (-228.03,-38.06) .. (-244.61,-38.80)
),
1,reverse ((-278.97,11.20)
 -- (-244.61,-38.80)
),
1,reverse ((-201.41,-9.31)
 .. controls (-201.41,-9.31) and (-214.30,-22.87) .. (-234.28,-2.06)
 .. controls (-254.30,18.79) and (-242.77,6.23) .. (-259.97,9.42)
 .. controls (-268.44,10.99) and (-278.97,11.20) .. (-278.97,11.20)
),
1,reverse ((-196.06,-25.34)
 .. controls (-196.06,-25.34) and (-200.66,-24.92) .. (-210.62,-22.71)
 .. controls (-216.34,-21.43) and (-229.25,-20.13) .. (-217.95,-19.07)
 .. controls (-206.65,-18.00) and (-198.93,-16.76) .. (-198.93,-16.76)
),
1,reverse ((-147.38,-23.02)
 .. controls (-151.11,-26.17) and (-168.85,-28.32) .. (-168.85,-28.32)
),
1,reverse ((-168.85,-28.32)
 .. controls (-168.85,-28.32) and (-171.49,-27.77) .. (-163.79,-23.64)
 .. controls (-155.94,-19.42) and (-143.78,-20.09) .. (-147.38,-23.02)
),
1,reverse ((-142.44,-3.56)
 .. controls (-142.44,-3.56) and (-152.55,-9.33) .. (-160.65,-8.04)
 .. controls (-185.24,-4.14) and (-186.17,3.65) .. (-187.95,9.41)
 .. controls (-189.73,15.14) and (-188.95,22.75) .. (-192.84,24.81)
 .. controls (-196.75,26.88) and (-200.42,25.46) .. (-216.53,32.55)
 .. controls (-232.65,39.64) and (-242.04,47.71) .. (-242.04,47.71)
 .. controls (-242.04,47.71) and (-253.71,59.75) .. (-259.02,55.30)
 .. controls (-286.97,31.89) and (-251.62,33.77) .. (-249.85,33.05)
 .. controls (-231.00,25.34) and (-213.63,22.28) .. (-215.48,7.67)
 .. controls (-216.99,-4.20) and (-204.12,7.15) .. (-198.08,-17.70)
 .. controls (-196.86,-22.69) and (-193.07,-34.74) .. (-177.41,-34.61)
 .. controls (-172.93,-34.58) and (-168.85,-28.32) .. (-168.85,-28.32)
),
1,reverse ((67.13,4.90)
 .. controls (67.13,4.90) and (53.81,-11.05) .. (3.53,-12.70)
 .. controls (-46.61,-14.35) and (-49.65,-11.49) .. (-49.65,-11.49)
 -- (-65.76,1.42)
 .. controls (-65.76,1.42) and (-78.72,8.93) .. (-125.92,4.49)
 .. controls (-131.97,3.92) and (-130.44,4.27) .. (-142.44,-3.56)
),
1,reverse ((237.77,-33.91)
 .. controls (237.77,-33.91) and (209.00,-24.66) .. (196.90,-24.08)
 .. controls (191.90,-23.84) and (192.78,-18.74) .. (188.11,-14.72)
 .. controls (183.41,-10.69) and (172.08,-0.47) .. (171.40,-0.21)
 .. controls (170.72,0.05) and (158.63,11.23) .. (158.63,11.23)
 .. controls (158.63,11.23) and (147.43,19.20) .. (138.82,20.29)
 .. controls (135.38,20.73) and (96.46,14.51) .. (88.47,13.79)
 .. controls (85.23,13.50) and (70.40,10.82) .. (67.13,4.90)
),
1,((237.77,-33.91)
 .. controls (237.77,-33.91) and (279.78,-41.31) .. (286.00,-42.73)
),
1,reverse ((241.31,-46.18)
 .. controls (241.31,-46.18) and (275.22,-50.37) .. (286.27,-51.44)
));
draw_upscrap(1)(1,((-176.40,-3.14)
 .. controls (-174.44,0.57) and (-144.03,38.76) .. (-146.53,43.16)
 .. controls (-149.03,47.56) and (-172.98,55.64) .. (-181.49,56.70)
 .. controls (-190.01,57.77) and (-245.50,67.58) .. (-245.50,67.58)
),
1,((-245.50,67.58)
 -- (-264.11,74.15)
),
1,reverse ((-250.32,60.81)
 -- (-269.25,69.04)
),
1,((-250.32,60.81)
 .. controls (-250.32,60.81) and (-191.23,51.28) .. (-185.48,43.81)
 .. controls (-179.73,36.36) and (-160.40,40.41) .. (-170.09,30.52)
 .. controls (-179.76,20.65) and (-186.19,3.65) .. (-186.19,3.65)
));
draw_upscrap(1)(1,((137.24,20.37)
 -- (137.24,20.37)));
draw_downscrap;
endfig;
beginfig(51);
ATTR__id := "l5_cav_pullover";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((237.77,-33.91)
 .. controls (237.77,-33.91) and (279.78,-41.31) .. (286.00,-42.73)
));
ATTR__id := "l7_cav_pullover";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((241.31,-46.18)
 .. controls (241.31,-46.18) and (275.22,-50.37) .. (286.27,-51.44)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((67.13,4.90)
 .. controls (67.13,4.90) and (53.81,-11.05) .. (3.53,-12.70)
 .. controls (-46.61,-14.35) and (-49.65,-11.49) .. (-49.65,-11.49)
 -- (-65.76,1.42)
 .. controls (-65.76,1.42) and (-78.72,8.93) .. (-125.92,4.49)
 .. controls (-131.97,3.92) and (-130.44,4.27) .. (-142.44,-3.56)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-176.40,-3.14)
 .. controls (-174.44,0.57) and (-144.03,38.76) .. (-146.53,43.16)
 .. controls (-149.03,47.56) and (-172.98,55.64) .. (-181.49,56.70)
 .. controls (-190.01,57.77) and (-245.50,67.58) .. (-245.50,67.58)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-196.06,-25.34)
 .. controls (-196.06,-25.34) and (-200.66,-24.92) .. (-210.62,-22.71)
 .. controls (-216.34,-21.43) and (-229.25,-20.13) .. (-217.95,-19.07)
 .. controls (-206.65,-18.00) and (-198.93,-16.76) .. (-198.93,-16.76)
));
drawoptions();
p_stalactites((-211.98,-33.26),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-201.41,-9.31)
 .. controls (-201.41,-9.31) and (-214.30,-22.87) .. (-234.28,-2.06)
 .. controls (-254.30,18.79) and (-242.77,6.23) .. (-259.97,9.42)
 .. controls (-268.44,10.99) and (-278.97,11.20) .. (-278.97,11.20)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-250.32,60.81)
 .. controls (-250.32,60.81) and (-191.23,51.28) .. (-185.48,43.81)
 .. controls (-179.73,36.36) and (-160.40,40.41) .. (-170.09,30.52)
 .. controls (-179.76,20.65) and (-186.19,3.65) .. (-186.19,3.65)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-245.50,67.58)
 -- (-264.11,74.15)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-250.32,60.81)
 -- (-269.25,69.04)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((237.77,-33.91)
 .. controls (237.77,-33.91) and (209.00,-24.66) .. (196.90,-24.08)
 .. controls (191.90,-23.84) and (192.78,-18.74) .. (188.11,-14.72)
 .. controls (183.41,-10.69) and (172.08,-0.47) .. (171.40,-0.21)
 .. controls (170.72,0.05) and (158.63,11.23) .. (158.63,11.23)
 .. controls (158.63,11.23) and (147.43,19.20) .. (138.82,20.29)
 .. controls (135.38,20.73) and (96.46,14.51) .. (88.47,13.79)
 .. controls (85.23,13.50) and (70.40,10.82) .. (67.13,4.90)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((241.31,-46.18)
 .. controls (241.31,-46.18) and (233.79,-47.86) .. (229.90,-48.40)
 .. controls (225.98,-48.94) and (211.18,-41.90) .. (191.17,-46.45)
 .. controls (172.78,-50.62) and (170.10,-62.42) .. (159.70,-62.05)
 .. controls (144.03,-61.50) and (139.08,-60.21) .. (135.69,-58.60)
 .. controls (128.30,-55.07) and (118.70,-50.55) .. (103.33,-52.34)
 .. controls (87.92,-54.12) and (75.27,-53.79) .. (69.93,-51.06)
 .. controls (64.61,-48.34) and (4.03,-41.60) .. (-6.26,-44.31)
 .. controls (-16.50,-47.02) and (-54.71,-48.91) .. (-63.34,-55.50)
 .. controls (-71.98,-62.08) and (-139.58,-55.91) .. (-144.74,-54.81)
 .. controls (-149.90,-53.71) and (-169.21,-50.42) .. (-180.52,-50.64)
 .. controls (-191.86,-50.86) and (-228.03,-38.06) .. (-244.61,-38.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-147.38,-23.02)
 .. controls (-151.11,-26.17) and (-168.85,-28.32) .. (-168.85,-28.32)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-168.85,-28.32)
 .. controls (-168.85,-28.32) and (-171.49,-27.77) .. (-163.79,-23.64)
 .. controls (-155.94,-19.42) and (-143.78,-20.09) .. (-147.38,-23.02)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-142.44,-3.56)
 .. controls (-142.44,-3.56) and (-152.55,-9.33) .. (-160.65,-8.04)
 .. controls (-185.24,-4.14) and (-186.17,3.65) .. (-187.95,9.41)
 .. controls (-189.73,15.14) and (-188.95,22.75) .. (-192.84,24.81)
 .. controls (-196.75,26.88) and (-200.42,25.46) .. (-216.53,32.55)
 .. controls (-232.65,39.64) and (-242.04,47.71) .. (-242.04,47.71)
 .. controls (-242.04,47.71) and (-253.71,59.75) .. (-259.02,55.30)
 .. controls (-286.97,31.89) and (-251.62,33.77) .. (-249.85,33.05)
 .. controls (-231.00,25.34) and (-213.63,22.28) .. (-215.48,7.67)
 .. controls (-216.99,-4.20) and (-204.12,7.15) .. (-198.08,-17.70)
 .. controls (-196.86,-22.69) and (-193.07,-34.74) .. (-177.41,-34.61)
 .. controls (-172.93,-34.58) and (-168.85,-28.32) .. (-168.85,-28.32)
));
drawoptions();
p_continuation((-277.94,38.33),0.0,1.41,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((237.06,-35.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((187.35,-36.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((136.75,-14.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((124.09,-13.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((74.17,-9.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-5.57,-30.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-73.57,-26.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-151.70,42.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-249.18,62.87),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-123.89,-24.88),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-183.69,-31.36),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-245.56,-15.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-193.37,-16.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-132.59,-28.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-264.79,63.44),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-244.65,36.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-203.41,14.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-178.68,-27.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-160.27,-10.78),1,0,"");
endfig;
beginfig(52);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char52 \char53 \mainfont{} etex,(-275.67,56.65),0.0,p_label_mode_altitude);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char56 \char50 \mainfont{} etex,(274.86,-6.31),0.0,p_label_mode_altitude);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char57 \mainfont{} etex, (237.06, -35.31), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char56 \mainfont{} etex, (187.35, -36.22), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char55 \mainfont{} etex, (136.75, -14.59), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char54 \mainfont{} etex, (124.09, -13.18), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char53 \mainfont{} etex, (74.17, -9.13), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char52 \mainfont{} etex, (-5.57, -30.31), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char48 \mainfont{} etex, (-73.57, -26.57), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char48 \mainfont{} etex, (-151.70, 42.60), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char49 \mainfont{} etex, (-249.18, 62.87), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char51 \mainfont{} etex, (-123.89, -24.88), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \char50 \mainfont{} etex, (-183.69, -31.36), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char56 \mainfont{} etex, (-245.56, -15.74), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char57 \mainfont{} etex, (-193.37, -16.15), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char49 \mainfont{} etex, (-132.59, -28.38), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char54 \mainfont{} etex, (-264.79, 63.44), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char53 \mainfont{} etex, (-244.65, 36.58), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char52 \mainfont{} etex, (-203.41, 14.15), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char51 \mainfont{} etex, (-178.68, -27.74), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char50 \mainfont{} etex, (-160.27, -10.78), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "sp_cav_pullover_5@Master";
ATTR__scrap := "sp_cav_pullover_5";
beginfig(53);
current_src := "datas/pull-over/pull-over_p.th2 [749]";
string area_border[];
area_border[1] := "x";
drawoptions();
a_clay(buildcycle(((272.45,27.25)
 -- (213.05,26.30)
 -- (214.12,25.13)
 -- (209.70,22.17)
 .. controls (209.70,22.17) and (167.65,-54.82) .. (214.89,-74.47)
 .. controls (265.27,-95.42) and (295.01,-54.18) .. (298.50,-51.63)
 .. controls (301.99,-49.09) and (308.14,-37.66) .. (310.26,-30.77)
 .. controls (312.37,-23.89) and (318.93,-8.66) .. (321.27,-6.74)
 .. controls (323.62,-4.83) and (336.67,4.01) .. (338.03,4.17)
 .. controls (339.39,4.33) and (371.13,-1.65) .. (372.01,-2.14)
 .. controls (372.89,-2.64) and (376.72,-2.81) .. (375.18,7.85)
 .. controls (373.65,18.52) and (381.41,30.34) .. (374.26,36.75)
 .. controls (367.11,43.16) and (333.65,55.07) .. (327.45,57.16)
 .. controls (321.25,59.25) and (284.02,67.31) .. (272.31,63.11)
 .. controls (260.59,58.92) and (251.06,53.02) .. (242.90,52.26)
 .. controls (234.74,51.50) and (215.83,57.30) .. (206.24,59.75)
 .. controls (196.64,62.20) and (56.17,79.74) .. (56.17,79.74)
 .. controls (56.17,79.74) and (11.56,70.12) .. (31.56,59.50)
 .. controls (51.57,48.88) and (95.13,71.55) .. (98.40,70.04)
 .. controls (100.77,68.95) and (157.14,66.80) .. (158.48,66.52)
 .. controls (159.82,66.24) and (190.14,38.57) .. (190.14,38.57)
 -- (274.53,33.24)
 .. controls (274.53,33.24) and (288.17,30.84) .. (282.43,28.62)
 .. controls (276.69,26.39) and (272.45,27.25) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_floormeander(((-137.70,-43.74)
 .. controls (-137.70,-43.74) and (-71.78,-59.21) .. (-36.25,-50.24)
 .. controls (-0.71,-41.27) and (-5.00,-41.29) .. (-5.00,-41.29)
));
ATTR__height := -1;
drawoptions();
l_pit(((109.56,-22.68)
 .. controls (109.56,-22.68) and (117.73,-26.40) .. (110.60,-36.96)
 .. controls (103.20,-47.93) and (88.88,-66.19) .. (91.10,-71.88)
 .. controls (91.51,-72.92) and (91.47,-79.26) .. (95.66,-85.70)
 .. controls (99.86,-92.16) and (126.95,-96.58) .. (133.36,-90.80)
 .. controls (133.89,-90.32) and (152.63,-81.07) .. (160.22,-59.30)
));
ATTR__height := -1;
drawoptions();
l_pit(((-232.32,-18.62)
 .. controls (-232.32,-18.62) and (-292.54,-68.12) .. (-228.47,-61.85)
));
ATTR__height := -1;
drawoptions();
l_pit(((42.73,16.58)
 .. controls (42.73,16.58) and (16.87,17.13) .. (8.93,11.00)
 .. controls (7.55,9.93) and (8.93,6.06) .. (9.10,4.70)
 .. controls (9.36,2.46) and (11.20,-12.94) .. (12.41,-15.92)
 .. controls (15.46,-23.45) and (17.51,-33.29) .. (27.47,-30.84)
 .. controls (36.78,-28.54) and (54.86,-23.11) .. (63.52,-20.57)
 .. controls (72.19,-18.04) and (97.73,-11.77) .. (109.56,-22.68)
));
ATTR__height := -1;
drawoptions();
l_pit(((142.20,40.86)
 .. controls (134.09,41.37) and (92.16,48.18) .. (89.78,19.12)
 .. controls (89.21,12.18) and (42.73,16.58) .. (42.73,16.58)
));
ATTR__height := -1;
drawoptions();
l_pit(((160.22,-59.30)
 .. controls (163.51,-51.78) and (166.53,-31.58) .. (172.22,-7.75)
 .. controls (177.88,15.92) and (166.16,17.34) .. (163.77,24.37)
 .. controls (161.37,31.40) and (162.75,31.58) .. (157.09,36.04)
 .. controls (151.43,40.50) and (142.20,40.86) .. (142.20,40.86)
));
drawoptions();
p_blocks((-382.51,58.19),0.0,1.00,(0,0));
drawoptions();
p_blocks((-281.49,88.62),177.3,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_pit(((1.85,79.14)
 .. controls (1.85,79.14) and (-30.42,67.82) .. (2.11,55.70)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-422.54,79.22)
 .. controls (-422.54,79.22) and (-407.39,75.58) .. (-389.13,80.59)
 .. controls (-370.86,85.59) and (-363.58,82.32) .. (-343.96,77.80)
 .. controls (-324.34,73.28) and (-324.41,66.97) .. (-283.24,70.45)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-283.24,70.45)
 .. controls (-283.24,70.45) and (-255.70,76.15) .. (-230.75,74.76)
 .. controls (-205.80,73.37) and (-213.59,65.83) .. (-178.74,63.78)
 .. controls (-143.94,61.74) and (-141.20,77.38) .. (-110.71,74.64)
 .. controls (-80.22,71.89) and (-84.65,68.50) .. (-57.90,67.51)
 .. controls (-31.16,66.51) and (-30.60,68.95) .. (-22.53,68.12)
));
ATTR__height := -1;
drawoptions();
l_pit(((394.99,26.55)
 .. controls (394.99,26.55) and (361.84,26.51) .. (378.67,10.17)
 .. controls (395.50,-6.17) and (402.89,-7.41) .. (424.27,-8.17)
 .. controls (445.66,-8.94) and (460.40,-7.15) .. (468.57,-0.99)
 .. controls (476.75,5.17) and (493.92,6.17) .. (466.48,12.18)
 .. controls (439.02,18.20) and (394.99,26.55) .. cycle
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((151.23,-72.51) -- (126.26,-30.64)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((151.23,-72.51) -- (215.16,-70.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((151.23,-72.51) -- (111.27,-90.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((111.27,-90.57) -- (151.23,-72.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((111.27,-90.57) -- (94.24,-49.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((94.24,-49.24) -- (111.27,-90.57)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((94.24,-49.24) -- (123.00,-29.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-364.63,90.03) -- (-183.64,80.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-183.64,80.72) -- (-364.63,90.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-183.64,80.72) -- (-40.40,74.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-40.40,74.60) -- (-183.64,80.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-40.40,74.60) -- (81.85,58.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((81.85,58.41) -- (-40.40,74.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((81.85,58.41) -- (116.10,47.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((116.10,47.52) -- (81.85,58.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((116.10,47.52) -- (292.12,45.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((292.12,45.23) -- (116.10,47.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((292.12,45.23) -- (313.25,21.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((433.18,-13.42) -- (313.25,21.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((313.25,21.98) -- (433.18,-13.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((313.25,21.98) -- (292.12,45.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((313.25,21.98) -- (292.30,-13.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((292.30,-13.38) -- (313.25,21.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((292.30,-13.38) -- (239.02,-34.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((239.02,-34.54) -- (292.30,-13.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((239.02,-34.54) -- (215.16,-70.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((215.16,-70.66) -- (239.02,-34.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((215.16,-70.66) -- (151.23,-72.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-248.89,-26.39) -- (-121.27,-32.73)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-121.27,-32.73) -- (-248.89,-26.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-121.27,-32.73) -- (-53.19,-50.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-53.19,-50.52) -- (-121.27,-32.73)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-53.19,-50.52) -- (22.72,-31.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((126.26,-30.64) -- (120.13,0.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((126.26,-30.64) -- (89.85,-16.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((126.26,-30.64) -- (151.23,-72.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((22.72,-31.38) -- (-53.19,-50.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((22.72,-31.38) -- (31.21,-26.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((31.21,-26.43) -- (22.72,-31.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((31.21,-26.43) -- (89.85,-16.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((89.85,-16.34) -- (31.21,-26.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((89.85,-16.34) -- (126.26,-30.64)));
endfig;
beginfig(54);
draw_upscrap(1)(1,((-453.10,105.21)
 .. controls (-436.02,109.14) and (-404.16,111.03) .. (-382.46,112.28)
 .. controls (-360.77,113.52) and (-358.06,111.12) .. (-351.45,110.38)
 .. controls (-323.66,107.27) and (-182.52,99.10) .. (-182.52,99.10)
 .. controls (-182.52,99.10) and (-55.82,88.36) .. (-34.17,84.21)
 .. controls (-12.52,80.05) and (74.05,71.69) .. (81.84,69.96)
 .. controls (89.61,68.24) and (115.20,71.07) .. (131.77,65.06)
 .. controls (148.45,59.01) and (221.92,52.30) .. (233.54,49.97)
 .. controls (245.17,47.65) and (274.33,63.02) .. (285.99,61.13)
 .. controls (297.62,59.23) and (297.07,62.16) .. (317.14,53.36)
 .. controls (371.07,29.68) and (370.25,32.88) .. (370.25,32.88)
 -- (421.27,34.12)
 .. controls (421.27,34.12) and (467.77,25.65) .. (475.75,17.84)
 .. controls (483.73,10.03) and (497.77,6.67) .. (485.83,1.81)
 .. controls (473.89,-3.04) and (476.20,-6.53) .. (460.68,-10.77)
 .. controls (447.32,-14.41) and (414.10,-13.57) .. (396.73,-8.93)
 .. controls (379.35,-4.29) and (363.63,1.85) .. (353.83,4.56)
 .. controls (344.04,7.27) and (319.89,7.06) .. (314.24,-3.04)
 .. controls (302.51,-24.00) and (300.53,-36.63) .. (290.24,-40.22)
 .. controls (279.95,-43.80) and (264.71,-42.44) .. (253.80,-50.06)
 .. controls (242.88,-57.69) and (232.24,-74.35) .. (221.01,-78.58)
 .. controls (209.78,-82.80) and (190.52,-60.73) .. (159.73,-83.65)
),
1,reverse ((98.27,-36.73)
 .. controls (98.27,-36.73) and (91.56,-44.81) .. (91.72,-47.06)
 .. controls (91.87,-49.31) and (82.78,-77.51) .. (88.96,-84.50)
 .. controls (95.16,-91.50) and (99.87,-96.67) .. (102.14,-96.32)
 .. controls (104.41,-95.97) and (129.81,-102.79) .. (137.77,-97.54)
 .. controls (145.75,-92.28) and (159.73,-83.65) .. (159.73,-83.65)
),
1,reverse ((89.12,30.35)
 .. controls (89.12,30.35) and (88.77,22.07) .. (87.61,21.01)
 .. controls (81.56,15.47) and (45.74,19.05) .. (39.46,18.76)
 .. controls (32.62,18.43) and (21.41,17.82) .. (7.93,13.74)
 .. controls (1.91,11.91) and (12.70,-15.76) .. (10.61,-20.34)
 .. controls (4.57,-33.60) and (-9.32,-37.26) .. (-22.75,-40.49)
 .. controls (-33.52,-43.07) and (-38.02,-15.06) .. (-39.94,-12.69)
 .. controls (-48.67,-1.94) and (-55.72,-3.65) .. (-55.72,-3.65)
 .. controls (-55.72,-3.65) and (-72.54,2.30) .. (-106.34,-13.67)
 .. controls (-125.09,-22.52) and (-153.46,-19.12) .. (-165.12,-17.68)
 .. controls (-176.77,-16.24) and (-202.75,-22.47) .. (-221.34,-20.03)
 .. controls (-239.94,-17.59) and (-248.57,-19.22) .. (-256.15,-26.98)
 .. controls (-263.72,-34.74) and (-272.28,-39.53) .. (-267.77,-49.21)
 .. controls (-263.26,-58.88) and (-267.52,-82.58) .. (-253.03,-86.18)
 .. controls (-238.55,-89.78) and (-247.13,-70.67) .. (-224.99,-59.75)
 .. controls (-202.85,-48.84) and (-190.48,-53.24) .. (-187.75,-53.82)
 .. controls (-156.73,-60.43) and (-156.24,-59.55) .. (-139.34,-64.61)
 .. controls (-122.46,-69.67) and (-105.38,-67.15) .. (-83.75,-74.40)
 .. controls (-64.23,-80.94) and (-58.72,-88.40) .. (-54.02,-88.84)
 .. controls (-49.31,-89.28) and (-47.70,-93.41) .. (-35.36,-79.79)
 .. controls (-23.02,-66.15) and (-35.84,-70.76) .. (-14.93,-56.83)
 .. controls (5.97,-42.90) and (10.67,-33.64) .. (22.12,-34.39)
 .. controls (25.24,-34.59) and (34.04,-30.49) .. (36.53,-30.15)
 .. controls (39.03,-29.82) and (52.23,-26.36) .. (58.83,-24.64)
 .. controls (65.44,-22.91) and (81.52,-16.65) .. (90.67,-18.88)
 .. controls (99.73,-21.09) and (99.01,-21.76) .. (104.16,-26.26)
 .. controls (109.35,-30.80) and (100.37,-34.12) .. (98.27,-36.73)
),
1,((89.12,30.35)
 .. controls (89.12,30.35) and (87.71,33.56) .. (94.31,36.17)
 .. controls (100.90,38.79) and (104.10,40.20) .. (105.30,41.72)
 .. controls (106.49,43.24) and (109.41,43.55) .. (109.41,43.55)
),
1,reverse ((105.59,47.54)
 .. controls (105.59,47.54) and (108.26,47.20) .. (109.79,46.46)
 .. controls (111.31,45.72) and (114.57,43.76) .. (109.41,43.55)
),
1,reverse ((-456.54,89.59)
 .. controls (-446.03,77.84) and (-446.64,77.54) .. (-446.31,76.95)
 .. controls (-439.65,65.14) and (-390.85,38.92) .. (-377.89,41.30)
 .. controls (-308.56,54.06) and (-194.94,49.67) .. (-184.87,48.30)
 .. controls (-174.79,46.94) and (-54.17,60.59) .. (-39.65,58.11)
 .. controls (-25.14,55.64) and (67.55,53.35) .. (81.37,50.47)
 .. controls (95.09,47.61) and (105.59,47.54) .. (105.59,47.54)
),
1,((-456.54,89.59)
 -- (-494.11,95.41)
),
1,reverse ((-453.10,105.21)
 -- (-490.90,106.30)
));
draw_upscrap(1)(1,((172.99,-46.37)
 .. controls (172.99,-46.37) and (161.62,-53.72) .. (171.90,-54.90)
),
1,((171.90,-54.90)
 .. controls (171.90,-54.90) and (196.97,-52.72) .. (207.70,-48.93)
 .. controls (218.44,-45.13) and (231.65,-36.69) .. (232.14,-30.63)
 .. controls (232.64,-24.57) and (228.45,-22.59) .. (208.58,-28.92)
 .. controls (201.22,-31.26) and (196.43,-34.66) .. (193.46,-35.87)
 .. controls (190.49,-37.08) and (172.99,-46.37) .. (172.99,-46.37)
));
draw_upscrap(1)(1,((143.28,44.63)
 .. controls (143.28,44.63) and (213.16,18.86) .. (234.85,19.47)
 .. controls (256.54,20.08) and (308.43,22.02) .. (302.11,26.15)
 .. controls (295.79,30.27) and (284.17,36.64) .. (270.90,37.69)
 .. controls (257.63,38.74) and (124.67,52.45) .. (143.28,44.63)
));
draw_downscrap;
endfig;
beginfig(55);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((89.12,30.35)
 .. controls (89.12,30.35) and (88.77,22.07) .. (87.61,21.01)
 .. controls (81.56,15.47) and (45.74,19.05) .. (39.46,18.76)
 .. controls (32.62,18.43) and (21.41,17.82) .. (7.93,13.74)
 .. controls (1.91,11.91) and (12.70,-15.76) .. (10.61,-20.34)
 .. controls (4.57,-33.60) and (-9.32,-37.26) .. (-22.75,-40.49)
 .. controls (-33.52,-43.07) and (-38.02,-15.06) .. (-39.94,-12.69)
 .. controls (-48.67,-1.94) and (-55.72,-3.65) .. (-55.72,-3.65)
 .. controls (-55.72,-3.65) and (-72.54,2.30) .. (-106.34,-13.67)
 .. controls (-125.09,-22.52) and (-153.46,-19.12) .. (-165.12,-17.68)
 .. controls (-176.77,-16.24) and (-202.75,-22.47) .. (-221.34,-20.03)
 .. controls (-239.94,-17.59) and (-248.57,-19.22) .. (-256.15,-26.98)
 .. controls (-263.72,-34.74) and (-272.28,-39.53) .. (-267.77,-49.21)
 .. controls (-263.26,-58.88) and (-267.52,-82.58) .. (-253.03,-86.18)
 .. controls (-238.55,-89.78) and (-247.13,-70.67) .. (-224.99,-59.75)
 .. controls (-202.85,-48.84) and (-190.48,-53.24) .. (-187.75,-53.82)
 .. controls (-156.73,-60.43) and (-156.24,-59.55) .. (-139.34,-64.61)
 .. controls (-122.46,-69.67) and (-105.38,-67.15) .. (-83.75,-74.40)
 .. controls (-64.23,-80.94) and (-58.72,-88.40) .. (-54.02,-88.84)
 .. controls (-49.31,-89.28) and (-47.70,-93.41) .. (-35.36,-79.79)
 .. controls (-23.02,-66.15) and (-35.84,-70.76) .. (-14.93,-56.83)
 .. controls (5.97,-42.90) and (10.67,-33.64) .. (22.12,-34.39)
 .. controls (25.24,-34.59) and (34.04,-30.49) .. (36.53,-30.15)
 .. controls (39.03,-29.82) and (52.23,-26.36) .. (58.83,-24.64)
 .. controls (65.44,-22.91) and (81.52,-16.65) .. (90.67,-18.88)
 .. controls (99.73,-21.09) and (99.01,-21.76) .. (104.16,-26.26)
 .. controls (109.35,-30.80) and (100.37,-34.12) .. (98.27,-36.73)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((89.12,30.35)
 .. controls (89.12,30.35) and (87.71,33.56) .. (94.31,36.17)
 .. controls (100.90,38.79) and (104.10,40.20) .. (105.30,41.72)
 .. controls (106.49,43.24) and (109.41,43.55) .. (109.41,43.55)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((98.27,-36.73)
 .. controls (98.27,-36.73) and (91.56,-44.81) .. (91.72,-47.06)
 .. controls (91.87,-49.31) and (82.78,-77.51) .. (88.96,-84.50)
 .. controls (95.16,-91.50) and (99.87,-96.67) .. (102.14,-96.32)
 .. controls (104.41,-95.97) and (129.81,-102.79) .. (137.77,-97.54)
 .. controls (145.75,-92.28) and (159.73,-83.65) .. (159.73,-83.65)
));
ATTR__height := -1;
drawoptions();
l_arrow(((56.62,-117.15)
 -- (83.90,-82.26)
),2);
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((107.91,-88.71)
 .. controls (107.62,-87.44) and (111.01,-78.54) .. (113.90,-68.34)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-256.13,-75.22)
 .. controls (-247.56,-65.24) and (-252.23,-59.17) .. (-240.70,-53.39)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((0.54,-38.38)
 .. controls (0.54,-38.38) and (8.82,-34.70) .. (26.79,-17.07)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((171.90,-54.90)
 .. controls (171.90,-54.90) and (196.97,-52.72) .. (207.70,-48.93)
 .. controls (218.44,-45.13) and (231.65,-36.69) .. (232.14,-30.63)
 .. controls (232.64,-24.57) and (228.45,-22.59) .. (208.58,-28.92)
 .. controls (201.22,-31.26) and (196.43,-34.66) .. (193.46,-35.87)
 .. controls (190.49,-37.08) and (172.99,-46.37) .. (172.99,-46.37)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((172.99,-46.37)
 .. controls (172.99,-46.37) and (161.62,-53.72) .. (171.90,-54.90)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((143.28,44.63)
 .. controls (143.28,44.63) and (213.16,18.86) .. (234.85,19.47)
 .. controls (256.54,20.08) and (308.43,22.02) .. (302.11,26.15)
 .. controls (295.79,30.27) and (284.17,36.64) .. (270.90,37.69)
 .. controls (257.63,38.74) and (124.67,52.45) .. (143.28,44.63)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-453.10,105.21)
 .. controls (-436.02,109.14) and (-404.16,111.03) .. (-382.46,112.28)
 .. controls (-360.77,113.52) and (-358.06,111.12) .. (-351.45,110.38)
 .. controls (-323.66,107.27) and (-182.52,99.10) .. (-182.52,99.10)
 .. controls (-182.52,99.10) and (-55.82,88.36) .. (-34.17,84.21)
 .. controls (-12.52,80.05) and (74.05,71.69) .. (81.84,69.96)
 .. controls (89.61,68.24) and (115.20,71.07) .. (131.77,65.06)
 .. controls (148.45,59.01) and (221.92,52.30) .. (233.54,49.97)
 .. controls (245.17,47.65) and (274.33,63.02) .. (285.99,61.13)
 .. controls (297.62,59.23) and (297.07,62.16) .. (317.14,53.36)
 .. controls (371.07,29.68) and (370.25,32.88) .. (370.25,32.88)
 -- (421.27,34.12)
 .. controls (421.27,34.12) and (467.77,25.65) .. (475.75,17.84)
 .. controls (483.73,10.03) and (497.77,6.67) .. (485.83,1.81)
 .. controls (473.89,-3.04) and (476.20,-6.53) .. (460.68,-10.77)
 .. controls (447.32,-14.41) and (414.10,-13.57) .. (396.73,-8.93)
 .. controls (379.35,-4.29) and (363.63,1.85) .. (353.83,4.56)
 .. controls (344.04,7.27) and (319.89,7.06) .. (314.24,-3.04)
 .. controls (302.51,-24.00) and (300.53,-36.63) .. (290.24,-40.22)
 .. controls (279.95,-43.80) and (264.71,-42.44) .. (253.80,-50.06)
 .. controls (242.88,-57.69) and (232.24,-74.35) .. (221.01,-78.58)
 .. controls (209.78,-82.80) and (190.52,-60.73) .. (159.73,-83.65)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-453.10,105.21)
 -- (-490.90,106.30)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((-456.54,89.59)
 -- (-494.11,95.41)
));
ATTR__height := -1;
drawoptions();
l_arrow(((-418.23,118.45)
 -- (-423.73,87.61)
),2);
drawoptions();
p_stalagmites((322.59,26.09),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((293.11,54.26),0.0,1.00,(0,0));
drawoptions();
p_stalactites((241.84,9.70),0.0,1.00,(0,0));
drawoptions();
p_stalactites((365.56,14.39),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-456.54,89.59)
 .. controls (-446.03,77.84) and (-446.64,77.54) .. (-446.31,76.95)
 .. controls (-439.65,65.14) and (-390.85,38.92) .. (-377.89,41.30)
 .. controls (-308.56,54.06) and (-194.94,49.67) .. (-184.87,48.30)
 .. controls (-174.79,46.94) and (-54.17,60.59) .. (-39.65,58.11)
 .. controls (-25.14,55.64) and (67.55,53.35) .. (81.37,50.47)
 .. controls (95.09,47.61) and (105.59,47.54) .. (105.59,47.54)
));
ATTR__height := -1;
drawoptions();
l_arrow(((-427.78,24.93)
 .. controls (-427.78,24.93) and (-421.58,32.30) .. (-399.38,54.02)
),2);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((105.59,47.54)
 .. controls (105.59,47.54) and (108.26,47.20) .. (109.79,46.46)
 .. controls (111.31,45.72) and (114.57,43.76) .. (109.41,43.55)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((89.85,-16.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((31.21,-26.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((22.72,-31.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((126.26,-30.64),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-53.19,-50.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-121.27,-32.73),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-248.89,-26.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((215.16,-70.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((239.02,-34.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((292.30,-13.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((313.25,21.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((433.18,-13.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((292.12,45.23),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((116.10,47.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((81.85,58.41),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-40.40,74.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-183.64,80.72),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-364.63,90.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((94.24,-49.24),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((111.27,-90.57),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((151.23,-72.51),1,0,"");
endfig;
beginfig(56);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char49 \char101 \char114 \ \char110 \char105 \char118 \char101 \char97 \char117 \mainfont{} etex,(48.36,-130.49),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char82 \char54 \ \char73 \char109 \char112 \ \char101 \char110 \ \char104 \char97 \char117 \char116 \mainfont{} etex,(-235.24,-3.84),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char52 \char55 \mainfont{} etex,(-238.79,-89.99),0.0,p_label_mode_altitude);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char51 \char53 \mainfont{} etex,(-469.84,127.85),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char80 \char52 \char48 \mainfont{} etex,(48.20,-67.74),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char77 \char111 \char117 \char99 \char104 \char116 \char105 \char113 \char117 \char101 \char115 \mainfont{} etex,(-404.23,143.26),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char82 \char50 \mainfont{} etex,(9.29,98.61),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char54 \char55 \mainfont{} etex,(406.79,-39.83),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char67 \char111 \char117 \char99 \char104 \char101 \ \char97 \ \char79 \char114 \char98 \char105 \char116 \char111 \mainfont{} etex,(-441.11,9.34),0.0,p_label_mode_label);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char57 \mainfont{} etex, (89.85, -16.34), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char48 \mainfont{} etex, (31.21, -26.43), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char49 \mainfont{} etex, (22.72, -31.38), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char56 \mainfont{} etex, (126.26, -30.64), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char50 \mainfont{} etex, (-53.19, -50.52), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char51 \mainfont{} etex, (-121.27, -32.73), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char52 \mainfont{} etex, (-248.89, -26.39), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char55 \mainfont{} etex, (215.16, -70.66), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char56 \mainfont{} etex, (239.02, -34.54), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char57 \mainfont{} etex, (292.30, -13.38), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char48 \mainfont{} etex, (313.25, 21.98), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char55 \mainfont{} etex, (433.18, -13.42), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char49 \mainfont{} etex, (292.12, 45.23), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char50 \mainfont{} etex, (116.10, 47.52), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char51 \mainfont{} etex, (81.85, 58.41), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char52 \mainfont{} etex, (-40.40, 74.60), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char53 \mainfont{} etex, (-183.64, 80.72), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char54 \mainfont{} etex, (-364.63, 90.03), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char52 \mainfont{} etex, (94.24, -49.24), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char53 \mainfont{} etex, (111.27, -90.57), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char54 \mainfont{} etex, (151.23, -72.51), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "sp_cav_pullover_8@Master";
ATTR__scrap := "sp_cav_pullover_8";
beginfig(57);
current_src := "datas/pull-over/pull-over_p.th2 [1445]";
string area_border[];
area_border[1] := "a";
drawoptions();
a_water(buildcycle(((106.48,-27.28)
 .. controls (106.48,-27.28) and (98.39,-21.98) .. (96.10,-33.35)
 .. controls (93.81,-44.73) and (76.20,-46.93) .. (84.54,-56.03)
 .. controls (85.40,-56.97) and (93.11,-65.86) .. (104.60,-65.68)
 .. controls (116.11,-65.49) and (115.58,-67.27) .. (121.83,-57.84)
 .. controls (125.84,-51.79) and (124.41,-43.53) .. (124.26,-42.87)
 .. controls (122.18,-33.58) and (106.48,-27.28) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_contour(((-34.64,60.00)
 .. controls (-34.64,60.00) and (-46.50,45.34) .. (-35.48,32.94)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((15.92,59.55)
 .. controls (15.92,59.55) and (4.09,34.78) .. (15.13,23.79)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((169.10,-59.57)
 .. controls (169.10,-59.57) and (154.40,-93.00) .. (164.60,-107.40)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((232.26,-55.93)
 .. controls (232.26,-55.93) and (221.73,-95.64) .. (231.30,-109.36)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((307.78,-68.70)
 .. controls (307.78,-68.70) and (300.41,-82.16) .. (307.64,-92.41)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((369.60,-72.94)
 .. controls (369.60,-72.94) and (357.11,-89.38) .. (365.97,-103.09)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((270.17,-61.85)
 .. controls (270.17,-61.85) and (263.74,-90.23) .. (271.51,-98.47)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((172.46,54.91)
 .. controls (172.46,54.91) and (163.46,21.08) .. (172.75,12.53)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((238.94,55.41)
 .. controls (238.94,55.41) and (230.49,18.86) .. (241.29,8.90)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((308.32,55.55)
 .. controls (308.32,55.55) and (293.94,27.15) .. (312.04,8.79)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((154.09,32.78)
 .. controls (154.09,32.78) and (345.92,34.94) .. (362.87,31.24)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((206.92,54.65)
 .. controls (206.92,54.65) and (200.77,29.03) .. (207.14,10.94)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((333.14,56.01)
 .. controls (333.14,56.01) and (319.43,25.43) .. (334.66,10.26)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-83.40,59.89)
 .. controls (-83.40,59.89) and (-90.45,41.43) .. (-82.76,35.94)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((273.09,53.57)
 .. controls (273.09,53.57) and (264.17,21.56) .. (275.50,8.21)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((355.85,54.97)
 .. controls (355.85,54.97) and (347.99,20.90) .. (359.88,9.80)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-319.53,106.66)
 .. controls (-319.53,106.66) and (-342.91,83.66) .. (-331.73,72.32)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-285.93,92.92)
 .. controls (-285.93,92.92) and (-304.59,84.11) .. (-299.71,68.10)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-260.94,82.53)
 .. controls (-260.94,82.53) and (-274.23,68.04) .. (-269.96,53.19)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-235.25,72.78)
 .. controls (-235.25,72.78) and (-250.28,49.80) .. (-241.98,39.26)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-120.21,59.31)
 .. controls (-120.21,59.31) and (-126.03,37.87) .. (-120.81,32.70)
),-1);
drawoptions();
p_blocks((-366.69,80.94),0.0,1.41,(0,0));
drawoptions();
p_blocks((-220.75,45.05),197.6,2.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((408.24,48.68)
 -- (409.91,50.63)
 -- (411.14,18.17)
 -- (409.55,17.80)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((409.91,50.63)
 -- (427.09,46.92)
 -- (429.92,14.85)
 -- (411.14,18.17)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((409.55,17.80)
 -- (427.74,11.36)
 -- (429.92,14.85)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((395.49,20.70)
 -- (393.06,21.72)
 -- (391.79,8.09)
 -- (394.92,7.72)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((395.49,20.70)
 -- (400.88,20.45)
 -- (401.25,8.32)
 -- (394.92,7.72)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((393.06,21.72)
 -- (399.40,22.54)
 -- (400.88,20.45)
));
ATTR__height := -1;
drawoptions();
l_pit(((-229.72,7.14)
 .. controls (-229.72,7.14) and (-241.26,5.01) .. (-243.75,-4.18)
 .. controls (-244.83,-8.18) and (-242.33,-7.62) .. (-240.62,-14.23)
 .. controls (-238.91,-20.83) and (-238.39,-19.28) .. (-235.52,-20.31)
 .. controls (-232.65,-21.34) and (-224.62,-27.12) .. (-222.89,-28.32)
 .. controls (-221.15,-29.53) and (-217.00,-36.72) .. (-212.97,-41.65)
 .. controls (-208.93,-46.57) and (-207.35,-46.42) .. (-205.00,-49.02)
 .. controls (-202.64,-51.61) and (-199.06,-52.01) .. (-190.81,-53.54)
 .. controls (-182.54,-55.06) and (-182.28,-39.53) .. (-179.16,-35.63)
 .. controls (-176.05,-31.72) and (-174.83,-16.01) .. (-174.40,-7.01)
 .. controls (-173.96,2.01) and (-177.19,5.09) .. (-184.67,8.83)
 .. controls (-192.15,12.58) and (-200.29,12.10) .. (-212.90,11.56)
 .. controls (-225.49,11.03) and (-229.72,7.14) .. cycle
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-181.72,-6.33) -- (-187.50,-73.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-181.72,-6.33) -- (-207.84,45.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-181.72,-6.33) -- (-212.22,-29.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((308.49,-82.14) -- (418.99,-94.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((308.49,-82.14) -- (189.39,-94.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((189.39,-94.15) -- (308.49,-82.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((189.39,-94.15) -- (106.54,-62.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.54,-62.14) -- (189.39,-94.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.54,-62.14) -- (70.46,-1.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((412.60,44.22) -- (287.58,41.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((287.58,41.05) -- (412.60,44.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((287.58,41.05) -- (70.46,-1.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((70.46,-1.77) -- (106.54,-62.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((70.46,-1.77) -- (287.58,41.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((70.46,-1.77) -- (15.47,44.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.47,44.56) -- (70.46,-1.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((15.47,44.56) -- (-207.84,45.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-423.42,77.13) -- (-358.73,79.68)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-358.73,79.68) -- (-423.42,77.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-358.73,79.68) -- (-291.74,89.16)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-291.74,89.16) -- (-358.73,79.68)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-291.74,89.16) -- (-207.84,45.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-207.84,45.95) -- (15.47,44.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-207.84,45.95) -- (-291.74,89.16)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-207.84,45.95) -- (-181.72,-6.33)));
endfig;
beginfig(58);
draw_upscrap(1)(1,((385.58,-67.65)
 .. controls (385.58,-67.65) and (347.66,-62.24) .. (311.61,-63.89)
 .. controls (275.66,-65.54) and (227.75,-44.30) .. (218.05,-44.12)
 .. controls (208.34,-43.93) and (195.80,-52.35) .. (184.18,-55.02)
 .. controls (172.56,-57.68) and (145.35,-61.52) .. (141.97,-55.97)
 .. controls (141.62,-55.40) and (129.70,-52.54) .. (133.84,-29.62)
 .. controls (135.06,-22.85) and (147.42,5.82) .. (173.69,8.66)
 .. controls (186.34,10.03) and (251.82,-2.17) .. (293.74,2.88)
 .. controls (335.68,7.94) and (378.58,4.67) .. (403.26,2.62)
 .. controls (427.94,0.58) and (431.20,8.06) .. (432.41,15.19)
 .. controls (433.63,22.32) and (430.59,34.83) .. (429.74,45.67)
 .. controls (428.88,56.53) and (426.32,54.61) .. (414.49,56.96)
 .. controls (402.66,59.30) and (347.20,58.07) .. (339.43,60.46)
 .. controls (331.65,62.84) and (226.47,58.47) .. (210.29,59.23)
 .. controls (194.10,59.99) and (115.40,55.14) .. (88.91,59.01)
 .. controls (62.46,62.87) and (45.50,61.28) .. (28.05,64.24)
 .. controls (23.29,65.05) and (24.23,64.61) .. (8.94,65.24)
 .. controls (-1.56,65.67) and (-153.49,62.64) .. (-158.00,62.59)
 .. controls (-162.52,62.54) and (-183.88,63.96) .. (-203.59,65.70)
 .. controls (-223.33,67.44) and (-287.45,99.07) .. (-288.32,99.57)
 .. controls (-289.20,100.06) and (-297.67,102.03) .. (-321.59,110.81)
 .. controls (-345.51,119.60) and (-348.66,114.79) .. (-350.45,115.10)
 .. controls (-352.24,115.41) and (-353.90,113.69) .. (-361.16,107.72)
 .. controls (-368.42,101.75) and (-369.35,86.70) .. (-382.65,86.63)
 .. controls (-395.94,86.57) and (-429.70,87.23) .. (-428.00,80.17)
 .. controls (-424.93,67.43) and (-380.95,70.46) .. (-376.94,68.80)
 .. controls (-376.47,68.61) and (-350.01,66.65) .. (-350.01,66.65)
 .. controls (-350.01,66.65) and (-319.56,67.47) .. (-311.68,67.54)
 .. controls (-303.79,67.62) and (-280.44,55.71) .. (-267.89,49.26)
 .. controls (-255.34,42.82) and (-223.94,27.45) .. (-222.52,26.19)
 .. controls (-216.91,21.21) and (-215.98,12.60) .. (-231.70,7.90)
 .. controls (-247.46,3.19) and (-247.90,-1.51) .. (-245.10,-9.07)
 .. controls (-242.31,-16.63) and (-245.42,-20.54) .. (-235.17,-22.35)
 .. controls (-224.93,-24.17) and (-216.73,-40.56) .. (-216.73,-40.56)
),
1,((-166.43,3.69)
 .. controls (-166.43,3.69) and (-160.92,24.29) .. (-149.34,25.22)
 .. controls (-137.78,26.15) and (-92.49,35.42) .. (-67.25,34.20)
),
1,((-67.25,34.20)
 .. controls (-67.25,34.20) and (-4.20,24.55) .. (11.81,19.42)
 .. controls (35.20,11.93) and (63.01,7.88) .. (63.33,-5.61)
 .. controls (63.64,-19.12) and (31.29,-90.01) .. (64.72,-92.57)
 .. controls (98.17,-95.12) and (81.25,-85.18) .. (113.14,-92.84)
 .. controls (145.06,-100.50) and (169.71,-135.10) .. (208.88,-121.24)
 .. controls (248.09,-107.36) and (298.51,-94.95) .. (310.59,-97.49)
 .. controls (322.68,-100.03) and (419.95,-117.65) .. (419.95,-117.65)
));
draw_downscrap;
endfig;
beginfig(59);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((385.58,-67.65)
 .. controls (385.58,-67.65) and (347.66,-62.24) .. (311.61,-63.89)
 .. controls (275.66,-65.54) and (227.75,-44.30) .. (218.05,-44.12)
 .. controls (208.34,-43.93) and (195.80,-52.35) .. (184.18,-55.02)
 .. controls (172.56,-57.68) and (145.35,-61.52) .. (141.97,-55.97)
 .. controls (141.62,-55.40) and (129.70,-52.54) .. (133.84,-29.62)
 .. controls (135.06,-22.85) and (147.42,5.82) .. (173.69,8.66)
 .. controls (186.34,10.03) and (251.82,-2.17) .. (293.74,2.88)
 .. controls (335.68,7.94) and (378.58,4.67) .. (403.26,2.62)
 .. controls (427.94,0.58) and (431.20,8.06) .. (432.41,15.19)
 .. controls (433.63,22.32) and (430.59,34.83) .. (429.74,45.67)
 .. controls (428.88,56.53) and (426.32,54.61) .. (414.49,56.96)
 .. controls (402.66,59.30) and (347.20,58.07) .. (339.43,60.46)
 .. controls (331.65,62.84) and (226.47,58.47) .. (210.29,59.23)
 .. controls (194.10,59.99) and (115.40,55.14) .. (88.91,59.01)
 .. controls (62.46,62.87) and (45.50,61.28) .. (28.05,64.24)
 .. controls (23.29,65.05) and (24.23,64.61) .. (8.94,65.24)
 .. controls (-1.56,65.67) and (-153.49,62.64) .. (-158.00,62.59)
 .. controls (-162.52,62.54) and (-183.88,63.96) .. (-203.59,65.70)
 .. controls (-223.33,67.44) and (-287.45,99.07) .. (-288.32,99.57)
 .. controls (-289.20,100.06) and (-297.67,102.03) .. (-321.59,110.81)
 .. controls (-345.51,119.60) and (-348.66,114.79) .. (-350.45,115.10)
 .. controls (-352.24,115.41) and (-353.90,113.69) .. (-361.16,107.72)
 .. controls (-368.42,101.75) and (-369.35,86.70) .. (-382.65,86.63)
 .. controls (-395.94,86.57) and (-429.70,87.23) .. (-428.00,80.17)
 .. controls (-424.93,67.43) and (-380.95,70.46) .. (-376.94,68.80)
 .. controls (-376.47,68.61) and (-350.01,66.65) .. (-350.01,66.65)
 .. controls (-350.01,66.65) and (-319.56,67.47) .. (-311.68,67.54)
 .. controls (-303.79,67.62) and (-280.44,55.71) .. (-267.89,49.26)
 .. controls (-255.34,42.82) and (-223.94,27.45) .. (-222.52,26.19)
 .. controls (-216.91,21.21) and (-215.98,12.60) .. (-231.70,7.90)
 .. controls (-247.46,3.19) and (-247.90,-1.51) .. (-245.10,-9.07)
 .. controls (-242.31,-16.63) and (-245.42,-20.54) .. (-235.17,-22.35)
 .. controls (-224.93,-24.17) and (-216.73,-40.56) .. (-216.73,-40.56)
));
ATTR__height := -1;
drawoptions();
l_gradient(((-337.77,87.47)
 -- (-237.63,55.31)
));
ATTR__height := -1;
drawoptions();
l_gradient(((-128.22,45.18)
 -- (48.85,39.95)
));
ATTR__height := -1;
drawoptions();
l_gradient(((140.52,-80.02)
 .. controls (140.52,-80.02) and (233.87,-97.07) .. (297.04,-82.01)
 .. controls (314.96,-77.74) and (385.24,-90.84) .. (397.27,-92.60)
));
drawoptions();
p_rimstonepool((62.17,-52.59),0.0,1.00,(0,0));
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_rimstonedam((118.19,-7.46),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-166.43,3.69)
 .. controls (-166.43,3.69) and (-160.92,24.29) .. (-149.34,25.22)
 .. controls (-137.78,26.15) and (-92.49,35.42) .. (-67.25,34.20)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-67.25,34.20)
 .. controls (-67.25,34.20) and (-4.20,24.55) .. (11.81,19.42)
 .. controls (35.20,11.93) and (63.01,7.88) .. (63.33,-5.61)
 .. controls (63.64,-19.12) and (31.29,-90.01) .. (64.72,-92.57)
 .. controls (98.17,-95.12) and (81.25,-85.18) .. (113.14,-92.84)
 .. controls (145.06,-100.50) and (169.71,-135.10) .. (208.88,-121.24)
 .. controls (248.09,-107.36) and (298.51,-94.95) .. (310.59,-97.49)
 .. controls (322.68,-100.03) and (419.95,-117.65) .. (419.95,-117.65)
));
drawoptions();
p_stalactite((185.28,-76.93),0.0,1.00,(0,0));
drawoptions();
p_stalactite((185.93,-109.43),0.0,1.00,(0,0));
drawoptions();
p_stalactite((286.22,-71.59),0.0,1.00,(0,0));
drawoptions();
p_stalactite((288.52,-91.10),0.0,1.00,(0,0));
drawoptions();
p_stalactite((400.46,-101.35),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((347.47,-97.37),0.0,1.00,(0,0));
drawoptions();
p_stalactites((69.45,-76.78),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((68.42,-23.15),0.0,1.00,(0,0));
drawoptions();
p_stalactites((235.70,-101.66),0.0,1.00,(0,0));
drawoptions();
p_stalactites((379.49,-73.84),0.0,1.00,(0,0));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-207.84,45.95),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-291.74,89.16),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-358.73,79.68),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-423.42,77.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((15.47,44.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((70.46,-1.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((287.58,41.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((412.60,44.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((106.54,-62.14),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((189.39,-94.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((308.49,-82.14),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-181.72,-6.33),1,0,"");
endfig;
beginfig(60);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char67 \char111 \char117 \char99 \char104 \char101 \ \thfc\char184 \ \thfb\char79 \char114 \char98 \char105 \char116 \char111 \mainfont{} etex,(-236.78,113.41),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char51 \char57 \mainfont{} etex,(-342.26,141.30),0.0,p_label_mode_altitude);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char54 \char54 \mainfont{} etex,(409.18,88.10),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char52 \char48 \mainfont{} etex,(-150.19,-15.58),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char50 \accent18 \char101 \char109 \char101 \ \char110 \char105 \char118 \char101 \char97 \char117 \mainfont{} etex,(-253.10,-35.51),0.0,p_label_mode_label);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char55 \mainfont{} etex, (-207.84, 45.95), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char56 \mainfont{} etex, (-291.74, 89.16), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char57 \mainfont{} etex, (-358.73, 79.68), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char48 \mainfont{} etex, (-423.42, 77.13), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char49 \mainfont{} etex, (15.47, 44.56), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char50 \mainfont{} etex, (70.46, -1.77), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char51 \mainfont{} etex, (287.58, 41.05), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char52 \mainfont{} etex, (412.60, 44.22), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char53 \mainfont{} etex, (106.54, -62.14), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char54 \mainfont{} etex, (189.39, -94.15), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \char55 \mainfont{} etex, (308.49, -82.14), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \char54 \mainfont{} etex, (-181.72, -6.33), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "sp_cav_pullover_7@Master";
ATTR__scrap := "sp_cav_pullover_7";
beginfig(61);
ATTR__height := -1;
drawoptions();
l_contour(((-37.19,-111.72)
 .. controls (-37.19,-111.72) and (-54.68,-159.11) .. (-35.29,-168.34)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-21.40,-111.31)
 .. controls (-21.40,-111.31) and (-34.46,-155.31) .. (-14.71,-166.59)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((-8.44,-108.75)
 .. controls (-8.44,-108.75) and (-12.88,-151.35) .. (9.93,-159.84)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((8.38,-100.51)
 .. controls (8.38,-100.51) and (7.35,-142.60) .. (28.37,-145.82)
),-1);
ATTR__height := -1;
drawoptions();
l_contour(((22.96,-92.17)
 .. controls (22.96,-92.17) and (25.29,-129.68) .. (49.59,-130.35)
),-1);
ATTR__height := -1;
drawoptions();
l_rockborder(((-173.71,-40.82)
 -- (-162.40,-54.18)
 -- (-136.31,-40.10)
 -- (-154.85,-22.57)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-173.71,-40.82)
 -- (-176.82,-30.32)
 -- (-151.89,-12.13)
 -- (-154.85,-22.57)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-151.89,-12.13)
 -- (-137.60,-24.28)
 -- (-136.31,-40.10)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-129.11,-49.89)
 -- (-117.31,-13.97)
 -- (-94.77,-18.17)
 -- (-111.53,-73.44)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-117.31,-13.97)
 -- (-110.71,-7.52)
 -- (-88.06,-14.20)
 -- (-94.77,-18.17)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-88.06,-14.20)
 -- (-99.29,-61.86)
 -- (-111.53,-73.44)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-155.88,-78.35)
 -- (-140.74,-67.58)
 -- (-133.51,-81.42)
 -- (-156.15,-79.46)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-140.74,-67.58)
 -- (-144.56,-57.72)
 -- (-158.62,-64.72)
 -- (-156.15,-79.46)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-142.34,-111.39)
 -- (-105.28,-138.08)
 -- (-91.34,-123.86)
 -- (-130.15,-105.88)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-142.34,-111.39)
 -- (-142.48,-99.91)
 -- (-128.58,-96.28)
 -- (-130.15,-105.88)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-128.58,-96.28)
 -- (-94.00,-113.16)
 -- (-91.34,-123.86)
));
drawoptions();
p_blocks((-72.66,-41.02),177.4,2.00,(0,0));
drawoptions();
p_blocks((-3.29,-124.08),97.4,1.41,(0,0));
drawoptions();
p_blocks((-74.22,-11.67),0.0,1.41,(0,0));
drawoptions();
p_blocks((79.53,83.41),197.4,2.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockborder(((-197.57,-45.33)
 -- (-174.53,-58.34)
 -- (-181.11,-88.42)
 -- (-210.98,-91.31)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-197.57,-45.33)
 -- (-193.17,-37.88)
 -- (-176.51,-47.67)
 -- (-174.53,-58.34)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-170.62,-90.26)
 -- (-169.43,-98.65)
 -- (-163.31,-97.81)
 -- (-162.69,-89.28)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-170.62,-90.26)
 -- (-167.32,-82.31)
 -- (-158.42,-84.53)
 -- (-162.69,-89.28)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-158.42,-84.53)
 -- (-156.76,-92.49)
 -- (-163.31,-97.81)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-79.18,-60.30)
 -- (-79.67,-65.91)
 -- (-75.64,-66.54)
 -- (-72.41,-59.93)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-79.18,-60.30)
 -- (-76.93,-55.45)
 -- (-68.84,-55.82)
 -- (-72.41,-59.93)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-68.84,-55.82)
 -- (-69.09,-61.21)
 -- (-75.64,-66.54)
));
drawoptions();
p_blocks((-126.98,-13.74),157.4,1.41,(0,0));
drawoptions();
p_blocks((-118.56,-89.09),267.4,1.41,(0,0));
drawoptions();
p_blocks((-76.01,-89.01),0.0,2.00,(0,0));
ATTR__height := -1;
drawoptions();
l_pit(((61.17,149.13)
 .. controls (61.17,149.13) and (99.61,103.42) .. (102.27,189.09)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-134.15,-67.80) -- (-72.91,8.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-134.15,-67.80) -- (-168.92,-126.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-168.92,-126.01) -- (-134.15,-67.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-168.92,-126.01) -- (-28.61,-156.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.61,-156.46) -- (-168.92,-126.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-28.61,-156.46) -- (82.78,-30.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((82.78,-30.31) -- (-28.61,-156.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((82.78,-30.31) -- (89.08,117.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((89.08,117.09) -- (82.78,-30.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((89.08,117.09) -- (94.86,183.88)));
endfig;
beginfig(62);
draw_upscrap(1)(1,((59.84,149.65)
 .. controls (59.84,149.65) and (70.66,138.16) .. (65.89,119.41)
 .. controls (63.96,111.84) and (38.95,44.07) .. (47.84,-11.75)
 .. controls (54.72,-54.89) and (32.47,-76.39) .. (25.56,-89.59)
 .. controls (19.42,-101.30) and (-1.93,-120.06) .. (-37.99,-119.34)
 .. controls (-64.08,-118.82) and (-85.90,-90.28) .. (-57.50,-63.75)
 .. controls (-37.73,-45.27) and (-69.09,-24.50) .. (-64.60,-13.00)
 .. controls (-57.32,5.67) and (-82.50,3.58) .. (-99.98,5.50)
 .. controls (-142.52,10.16) and (-125.82,-3.44) .. (-151.89,-12.13)
 .. controls (-152.56,-12.35) and (-189.91,-45.24) .. (-203.49,-85.35)
 .. controls (-209.92,-104.34) and (-180.28,-147.71) .. (-167.02,-133.88)
 .. controls (-144.31,-110.17) and (-115.48,-154.57) .. (-83.52,-159.36)
 .. controls (-53.10,-163.91) and (-11.75,-161.09) .. (3.30,-152.10)
 .. controls (9.76,-148.24) and (39.43,-135.74) .. (48.28,-124.43)
 .. controls (57.14,-113.12) and (88.54,-71.98) .. (94.47,-41.17)
 .. controls (100.39,-10.36) and (79.66,47.36) .. (96.33,81.27)
 .. controls (99.53,87.79) and (108.36,117.21) .. (109.35,118.96)
 .. controls (110.33,120.72) and (113.53,146.01) .. (112.19,160.48)
 .. controls (110.84,174.95) and (104.05,179.10) .. (110.15,193.90)
));
draw_downscrap;
endfig;
beginfig(63);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((59.84,149.65)
 .. controls (59.84,149.65) and (70.66,138.16) .. (65.89,119.41)
 .. controls (63.96,111.84) and (38.95,44.07) .. (47.84,-11.75)
 .. controls (54.72,-54.89) and (32.47,-76.39) .. (25.56,-89.59)
 .. controls (19.42,-101.30) and (-1.93,-120.06) .. (-37.99,-119.34)
 .. controls (-64.08,-118.82) and (-85.90,-90.28) .. (-57.50,-63.75)
 .. controls (-37.73,-45.27) and (-69.09,-24.50) .. (-64.60,-13.00)
 .. controls (-57.32,5.67) and (-82.50,3.58) .. (-99.98,5.50)
 .. controls (-142.52,10.16) and (-125.82,-3.44) .. (-151.89,-12.13)
 .. controls (-152.56,-12.35) and (-189.91,-45.24) .. (-203.49,-85.35)
 .. controls (-209.92,-104.34) and (-180.28,-147.71) .. (-167.02,-133.88)
 .. controls (-144.31,-110.17) and (-115.48,-154.57) .. (-83.52,-159.36)
 .. controls (-53.10,-163.91) and (-11.75,-161.09) .. (3.30,-152.10)
 .. controls (9.76,-148.24) and (39.43,-135.74) .. (48.28,-124.43)
 .. controls (57.14,-113.12) and (88.54,-71.98) .. (94.47,-41.17)
 .. controls (100.39,-10.36) and (79.66,47.36) .. (96.33,81.27)
 .. controls (99.53,87.79) and (108.36,117.21) .. (109.35,118.96)
 .. controls (110.33,120.72) and (113.53,146.01) .. (112.19,160.48)
 .. controls (110.84,174.95) and (104.05,179.10) .. (110.15,193.90)
));
ATTR__height := -1;
drawoptions();
l_arrow(((205.57,95.79)
 -- (126.93,133.68)
),2);
ATTR__height := -1;
drawoptions();
l_gradient(((-52.95,-136.22)
 .. controls (-52.95,-136.22) and (0.87,-136.44) .. (32.06,-109.71)
));
ATTR__height := -1;
drawoptions();
l_arrow(((53.33,-171.07)
 .. controls (52.43,-171.03) and (15.26,-156.70) .. (15.26,-156.70)
),2);
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((-223.18,-155.36)
 .. controls (-223.18,-155.36) and (-192.36,-121.89) .. (-177.10,-123.05)
 .. controls (-161.84,-124.21) and (-137.53,-134.11) .. (-124.19,-137.88)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((33.39,-100.54)
 .. controls (33.39,-100.54) and (62.33,-54.11) .. (64.95,-26.74)
));
ATTR__height := -1;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((86.93,111.67)
 -- (80.24,152.07)
));
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((89.08,117.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((82.78,-30.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-28.61,-156.46),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-168.92,-126.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-134.15,-67.80),1,0,"");
endfig;
beginfig(64);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char50 \char101 \char109 \char101 \ \char110 \char105 \char118 \char101 \char97 \char117 \mainfont{} etex,(220.07,68.77),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.lft(btex \thaltitude \thhugesize \thfb\char45 \char51 \char57 \mainfont{} etex,(-177.36,-191.49),0.0,p_label_mode_altitude);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char67 \char111 \char117 \char99 \char104 \char101 \ \thfc\char184 \ \thfb\char79 \char114 \char98 \char105 \char116 \char111 \mainfont{} etex,(122.24,-181.01),0.0,p_label_mode_label);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char55 \mainfont{} etex, (89.08, 117.09), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char56 \mainfont{} etex, (82.78, -30.31), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \char57 \mainfont{} etex, (-28.61, -156.46), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \char48 \mainfont{} etex, (-168.92, -126.01), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \char49 \mainfont{} etex, (-134.15, -67.80), 0.0, p_label_mode_debugstation);
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
current_scrap := "0-100_sp1@Master";
ATTR__scrap := "0-100_sp1";
beginfig(65);
current_src := "datas/0-100/0-100_p.th2 [120]";
string area_border[];
area_border[1] := "l182-729-1093";
drawoptions();
a_water(buildcycle(((-43.94,11.80)
 .. controls (-43.94,11.80) and (-53.23,5.70) .. (-51.32,3.13)
 .. controls (-49.42,0.56) and (-47.47,-6.06) .. (-45.13,-4.14)
 .. controls (-42.79,-2.22) and (-37.88,1.61) .. (-36.88,3.81)
 .. controls (-35.88,6.02) and (-42.80,12.19) .. (-43.94,11.80)
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((-159.95,113.69)
 -- (-165.16,98.41)
 -- (-151.96,91.95)
 -- (-137.31,102.51)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-159.95,113.69)
 -- (-154.71,120.19)
 -- (-139.28,113.18)
 -- (-137.31,102.51)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-134.45,110.70)
 -- (-134.89,101.27)
 -- (-120.31,100.36)
 -- (-119.44,109.32)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-134.89,101.27)
 -- (-140.09,95.89)
 -- (-125.98,94.55)
 -- (-120.31,100.36)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-140.09,95.89)
 -- (-141.26,99.77)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-134.45,110.70)
 -- (-138.33,109.53)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-114.59,92.67)
 -- (-114.34,102.78)
 -- (-100.98,104.64)
 -- (-97.95,92.35)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-100.98,104.64)
 -- (-96.78,107.83)
 -- (-93.00,101.80)
 -- (-97.95,92.35)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-114.34,102.78)
 -- (-107.73,109.46)
 -- (-96.78,107.83)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-70.63,103.46)
 -- (-68.50,95.93)
 -- (-61.39,98.75)
 -- (-63.14,104.69)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-70.63,103.46)
 -- (-65.49,107.27)
 -- (-55.14,107.02)
 -- (-63.14,104.69)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-55.14,107.02)
 -- (-53.71,99.07)
 -- (-61.39,98.75)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((114.81,-109.30)
 .. controls (81.38,-95.72) and (104.44,-119.65) .. (104.44,-119.65)
));
drawoptions();
p_debris((196.78,-67.39),59.4,1.00,(0,0));
drawoptions();
p_debris((151.69,-121.09),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_border_visible(((104.44,-119.65)
 .. controls (104.44,-119.65) and (122.32,-127.87) .. (131.64,-130.75)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((137.69,-121.34)
 .. controls (131.20,-120.38) and (114.81,-109.30) .. (114.81,-109.30)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((-38.33,11.31)
 .. controls (-38.33,11.31) and (-5.55,57.99) .. (-2.16,58.28)
 .. controls (1.23,58.57) and (5.31,64.02) .. (24.22,63.61)
));
ATTR__height := -1;
drawoptions();
l_pit(((-175.72,117.80)
 .. controls (-175.72,117.80) and (-179.49,108.50) .. (-176.54,105.01)
 .. controls (-173.77,101.73) and (-170.10,98.41) .. (-167.72,101.23)
 .. controls (-165.34,104.04) and (-164.16,119.72) .. (-169.31,120.19)
 .. controls (-174.46,120.66) and (-175.72,117.80) .. cycle
));
ATTR__height := -1;
drawoptions();
l_pit(((29.21,102.64)
 .. controls (18.63,108.99) and (21.64,94.84) .. (21.64,94.84)
));
ATTR__height := -1;
drawoptions();
l_pit(((67.24,68.60)
 .. controls (67.24,68.60) and (59.76,52.69) .. (64.54,49.32)
));
ATTR__height := -1;
drawoptions();
l_pit(((47.57,80.79)
 .. controls (43.62,82.78) and (33.77,74.69) .. (33.77,74.69)
));
ATTR__height := -1;
drawoptions();
l_pit(((52.82,23.33)
 .. controls (55.84,35.82) and (40.17,33.41) .. (40.17,33.41)
));
ATTR__height := -1;
drawoptions();
l_pit(((73.74,-34.12)
 .. controls (53.56,-9.34) and (42.40,-35.13) .. (42.40,-35.13)
));
ATTR__height := -1;
drawoptions();
l_pit(((105.91,-96.98)
 .. controls (75.20,-89.24) and (83.44,-115.56) .. (83.44,-115.56)
));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((202.72,-63.21) -- (189.96,-31.68)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((202.72,-63.21) -- (141.91,-128.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((107.54,-224.42) -- (106.68,-208.73)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.68,-208.73) -- (107.54,-224.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.68,-208.73) -- (106.63,-188.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.63,-188.03) -- (106.68,-208.73)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((106.63,-188.03) -- (141.91,-128.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((141.91,-128.29) -- (202.72,-63.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((141.91,-128.29) -- (106.63,-188.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((141.91,-128.29) -- (98.70,-107.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((98.70,-107.81) -- (141.91,-128.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((98.70,-107.81) -- (64.16,-75.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((64.16,-75.53) -- (98.70,-107.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((64.16,-75.53) -- (67.94,-46.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((67.94,-46.66) -- (64.16,-75.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((67.94,-46.66) -- (59.63,-4.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((59.63,-4.04) -- (67.94,-46.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((59.63,-4.04) -- (37.90,22.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((37.90,22.28) -- (59.63,-4.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((37.90,22.28) -- (48.52,31.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((48.52,31.53) -- (37.90,22.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((48.52,31.53) -- (69.64,54.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((69.64,54.86) -- (48.52,31.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((69.64,54.86) -- (82.02,50.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((82.02,50.36) -- (69.64,54.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((82.02,50.36) -- (49.18,65.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-48.01,-2.08) -- (-0.12,61.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-0.12,61.10) -- (-48.01,-2.08)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-0.12,61.10) -- (49.18,65.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((49.18,65.10) -- (82.02,50.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((49.18,65.10) -- (-0.12,61.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((49.18,65.10) -- (28.53,93.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((28.53,93.17) -- (49.18,65.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((28.53,93.17) -- (14.67,112.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.67,112.01) -- (28.53,93.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((14.67,112.01) -- (-106.90,91.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-106.90,91.14) -- (14.67,112.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-106.90,91.14) -- (-152.06,113.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-152.06,113.52) -- (-106.90,91.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-152.06,113.52) -- (-157.11,142.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-171.88,122.65) -- (-165.46,120.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-165.46,120.79) -- (-171.88,122.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-165.46,120.79) -- (-157.11,142.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-157.11,142.94) -- (-152.06,113.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-157.11,142.94) -- (-165.46,120.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-157.11,142.94) -- (-148.42,169.60)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-148.42,169.60) -- (-157.11,142.94)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-148.42,169.60) -- (-126.08,165.75)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-126.08,165.75) -- (-148.42,169.60)));
endfig;
beginfig(66);
draw_upscrap(1)(1,((40.34,13.27)
 .. controls (43.70,9.40) and (53.68,-1.90) .. (53.30,-10.00)
 .. controls (52.93,-18.07) and (41.97,-30.39) .. (42.40,-35.13)
 .. controls (42.84,-39.88) and (64.31,-73.15) .. (64.16,-75.53)
 .. controls (64.02,-77.91) and (76.63,-111.86) .. (83.44,-115.56)
 .. controls (90.26,-119.25) and (131.18,-130.95) .. (133.94,-134.45)
 .. controls (136.71,-137.97) and (112.42,-170.68) .. (103.89,-179.76)
 .. controls (95.36,-188.83) and (104.85,-223.08) .. (104.85,-223.08)
),
1,((110.19,-224.90)
 .. controls (110.06,-182.75) and (121.78,-178.15) .. (123.85,-172.33)
 .. controls (135.51,-139.49) and (155.27,-126.20) .. (155.27,-126.20)
 .. controls (155.27,-126.20) and (189.04,-83.46) .. (196.56,-76.83)
 .. controls (204.09,-70.20) and (209.10,-64.37) .. (209.50,-60.57)
),
1,((192.55,-61.35)
 .. controls (193.78,-63.88) and (156.95,-100.17) .. (147.04,-114.56)
 .. controls (137.12,-128.96) and (119.96,-104.60) .. (105.91,-96.98)
 .. controls (91.86,-89.37) and (80.16,-51.09) .. (79.84,-48.37)
 .. controls (79.52,-45.65) and (59.63,-4.04) .. (59.63,-4.04)
 .. controls (59.63,-4.04) and (57.27,8.73) .. (53.00,14.31)
),
1,((53.00,14.31)
 .. controls (48.76,19.89) and (51.78,21.12) .. (53.88,26.45)
),
1,((53.88,26.45)
 .. controls (55.91,31.78) and (80.71,46.56) .. (83.29,48.71)
 .. controls (85.87,50.85) and (85.16,76.56) .. (81.15,77.66)
 .. controls (69.38,80.90) and (69.98,64.64) .. (62.29,62.99)
 .. controls (54.54,61.32) and (53.65,71.28) .. (52.19,73.82)
),
1,((52.19,73.82)
 .. controls (50.74,76.37) and (30.80,103.24) .. (26.05,108.21)
),
1,((26.05,108.21)
 .. controls (20.85,113.63) and (17.38,116.71) .. (2.43,114.92)
 .. controls (-12.51,113.13) and (-30.51,108.80) .. (-69.63,110.40)
 .. controls (-81.99,110.90) and (-102.67,116.65) .. (-114.51,118.55)
 .. controls (-126.35,120.45) and (-135.58,115.48) .. (-141.31,118.00)
 .. controls (-146.00,120.06) and (-150.05,132.14) .. (-150.36,136.86)
 .. controls (-150.63,140.91) and (-132.71,156.75) .. (-132.71,156.75)
),
1,((-132.71,156.75)
 .. controls (-132.71,156.75) and (-123.32,174.35) .. (-127.18,179.43)
 .. controls (-130.35,183.61) and (-128.88,186.24) .. (-137.97,183.96)
 .. controls (-147.06,181.68) and (-149.54,170.12) .. (-149.69,168.99)
),
1,((-149.69,168.99)
 .. controls (-149.69,168.99) and (-174.51,124.26) .. (-174.58,122.69)
 .. controls (-174.66,121.12) and (-187.09,106.14) .. (-169.92,97.51)
 .. controls (-151.68,88.33) and (-143.24,86.14) .. (-137.16,86.30)
 .. controls (-131.08,86.47) and (-133.00,90.79) .. (-119.64,90.66)
 .. controls (-107.49,90.54) and (-105.71,89.78) .. (-94.43,90.38)
 .. controls (-42.73,93.15) and (9.80,103.75) .. (9.80,103.75)
 .. controls (9.80,103.75) and (13.06,105.85) .. (20.14,96.94)
),
1,((20.14,96.94)
 .. controls (27.21,88.06) and (21.20,89.87) .. (26.59,84.48)
 .. controls (31.53,79.53) and (40.88,72.55) .. (35.86,71.43)
),
1,((35.86,71.43)
 .. controls (22.16,68.34) and (-6.08,66.12) .. (-7.35,63.02)
 .. controls (-8.61,59.93) and (-52.14,9.92) .. (-53.67,5.94)
 .. controls (-54.91,2.73) and (-48.88,-12.30) .. (-39.88,-2.58)
 .. controls (-30.87,7.14) and (-10.14,46.49) .. (0.76,48.23)
 .. controls (11.65,49.98) and (39.63,61.86) .. (45.00,59.73)
 .. controls (52.08,56.93) and (69.83,52.22) .. (65.58,47.71)
 .. controls (61.34,43.19) and (51.09,34.92) .. (47.24,34.21)
 .. controls (43.35,33.50) and (43.83,33.92) .. (40.17,33.41)
),
1,((40.17,33.41)
 .. controls (30.27,31.99) and (28.94,25.58) .. (33.27,22.60)
 .. controls (38.54,18.97) and (36.67,17.47) .. (40.34,13.27)
));
draw_downscrap;
endfig;
beginfig(67);
drawoptions();
p_entrance((-127.70,216.32),167.3,2.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((110.19,-224.90)
 .. controls (110.06,-182.75) and (121.78,-178.15) .. (123.85,-172.33)
 .. controls (135.51,-139.49) and (155.27,-126.20) .. (155.27,-126.20)
 .. controls (155.27,-126.20) and (189.04,-83.46) .. (196.56,-76.83)
 .. controls (204.09,-70.20) and (209.10,-64.37) .. (209.50,-60.57)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((40.34,13.27)
 .. controls (43.70,9.40) and (53.68,-1.90) .. (53.30,-10.00)
 .. controls (52.93,-18.07) and (41.97,-30.39) .. (42.40,-35.13)
 .. controls (42.84,-39.88) and (64.31,-73.15) .. (64.16,-75.53)
 .. controls (64.02,-77.91) and (76.63,-111.86) .. (83.44,-115.56)
 .. controls (90.26,-119.25) and (131.18,-130.95) .. (133.94,-134.45)
 .. controls (136.71,-137.97) and (112.42,-170.68) .. (103.89,-179.76)
 .. controls (95.36,-188.83) and (104.85,-223.08) .. (104.85,-223.08)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((40.17,33.41)
 .. controls (30.27,31.99) and (28.94,25.58) .. (33.27,22.60)
 .. controls (38.54,18.97) and (36.67,17.47) .. (40.34,13.27)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((35.86,71.43)
 .. controls (22.16,68.34) and (-6.08,66.12) .. (-7.35,63.02)
 .. controls (-8.61,59.93) and (-52.14,9.92) .. (-53.67,5.94)
 .. controls (-54.91,2.73) and (-48.88,-12.30) .. (-39.88,-2.58)
 .. controls (-30.87,7.14) and (-10.14,46.49) .. (0.76,48.23)
 .. controls (11.65,49.98) and (39.63,61.86) .. (45.00,59.73)
 .. controls (52.08,56.93) and (69.83,52.22) .. (65.58,47.71)
 .. controls (61.34,43.19) and (51.09,34.92) .. (47.24,34.21)
 .. controls (43.35,33.50) and (43.83,33.92) .. (40.17,33.41)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((20.14,96.94)
 .. controls (27.21,88.06) and (21.20,89.87) .. (26.59,84.48)
 .. controls (31.53,79.53) and (40.88,72.55) .. (35.86,71.43)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-149.69,168.99)
 .. controls (-149.69,168.99) and (-174.51,124.26) .. (-174.58,122.69)
 .. controls (-174.66,121.12) and (-187.09,106.14) .. (-169.92,97.51)
 .. controls (-151.68,88.33) and (-143.24,86.14) .. (-137.16,86.30)
 .. controls (-131.08,86.47) and (-133.00,90.79) .. (-119.64,90.66)
 .. controls (-107.49,90.54) and (-105.71,89.78) .. (-94.43,90.38)
 .. controls (-42.73,93.15) and (9.80,103.75) .. (9.80,103.75)
 .. controls (9.80,103.75) and (13.06,105.85) .. (20.14,96.94)
));
drawoptions();
p_dig((131.39,-219.74),0.0,1.00,(0,0));
drawoptions();
p_airdraught((167.05,-72.28),137.3,1.00,(0,0));
drawoptions();
p_airdraught((109.53,-249.69),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((192.55,-61.35)
 .. controls (193.78,-63.88) and (156.95,-100.17) .. (147.04,-114.56)
 .. controls (137.12,-128.96) and (119.96,-104.60) .. (105.91,-96.98)
 .. controls (91.86,-89.37) and (80.16,-51.09) .. (79.84,-48.37)
 .. controls (79.52,-45.65) and (59.63,-4.04) .. (59.63,-4.04)
 .. controls (59.63,-4.04) and (57.27,8.73) .. (53.00,14.31)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((53.00,14.31)
 .. controls (48.76,19.89) and (51.78,21.12) .. (53.88,26.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((53.88,26.45)
 .. controls (55.91,31.78) and (80.71,46.56) .. (83.29,48.71)
 .. controls (85.87,50.85) and (85.16,76.56) .. (81.15,77.66)
 .. controls (69.38,80.90) and (69.98,64.64) .. (62.29,62.99)
 .. controls (54.54,61.32) and (53.65,71.28) .. (52.19,73.82)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((52.19,73.82)
 .. controls (50.74,76.37) and (30.80,103.24) .. (26.05,108.21)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((26.05,108.21)
 .. controls (20.85,113.63) and (17.38,116.71) .. (2.43,114.92)
 .. controls (-12.51,113.13) and (-30.51,108.80) .. (-69.63,110.40)
 .. controls (-81.99,110.90) and (-102.67,116.65) .. (-114.51,118.55)
 .. controls (-126.35,120.45) and (-135.58,115.48) .. (-141.31,118.00)
 .. controls (-146.00,120.06) and (-150.05,132.14) .. (-150.36,136.86)
 .. controls (-150.63,140.91) and (-132.71,156.75) .. (-132.71,156.75)
));
ATTR__height := -1;
drawoptions();
l_wall_pit(((-132.71,156.75)
 .. controls (-132.71,156.75) and (-123.32,174.35) .. (-127.18,179.43)
 .. controls (-130.35,183.61) and (-128.88,186.24) .. (-137.97,183.96)
 .. controls (-147.06,181.68) and (-149.54,170.12) .. (-149.69,168.99)
));
ATTR__height := -1;
drawoptions();
l_arrow(((21.48,6.18)
 .. controls (21.23,10.93) and (21.65,20.41) .. (34.70,13.72)
),2);
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-148.42,169.60),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-157.11,142.94),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-165.46,120.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-171.88,122.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-152.06,113.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-106.90,91.14),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((14.67,112.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((28.53,93.17),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((49.18,65.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-0.12,61.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((-48.01,-2.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((82.02,50.36),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((69.64,54.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((48.52,31.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((37.90,22.28),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((59.63,-4.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((67.94,-46.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((64.16,-75.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((98.70,-107.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((141.91,-128.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((106.63,-188.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((106.68,-208.73),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((107.54,-224.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station((202.72,-63.21),1,0,"");
endfig;
beginfig(68);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char71 \char111 \char117 \char102 \char102 \char114 \char101 \ \char67 \char97 \char118 \char101 \char114 \char110 \char105 \char99 \char111 \char108 \char101 \mainfont{} etex,(-110.44,249.73),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thsmallsize \thfb\char80 \char116 \char115 \ \char98 \char111 \char114 \char103 \char110 \char101 \mainfont{} etex,(-207.53,115.67),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((95.3616,-188.834),(104.85,-223.08),(114.343,-257.317),btex \thwallaltitude \thfb\char45 \char55 \char51 \mainfont{} etex);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((-52.1354,9.92281),(-53.67,5.94),(-54.909,2.72814),btex \thwallaltitude \thfb\char45 \char51 \char52 \mainfont{} etex);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((-102.672,116.652),(-114.51,118.55),(-126.35,120.448),btex \thwallaltitude \thfb\char45 \char49 \char51 \mainfont{} etex);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char56 \mainfont{} etex,(48.84,97.89),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char82 \char52 \mainfont{} etex,(103.72,56.40),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char54 \mainfont{} etex,(78.66,16.71),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char49 \char48 \mainfont{} etex,(27.03,-36.06),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char49 \char49 \mainfont{} etex,(81.50,-133.48),0.0,p_label_mode_label);
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((-149.536,170.124),(-149.69,168.99),(-149.844,167.855),btex \thwallaltitude \thfb\char45 \char49 \mainfont{} etex);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char80 \char49 \char48 \mainfont{} etex,(-107.77,171.35),0.0,p_label_mode_label);
drawoptions();
p_label(btex \thlabel\thsmallsize \thfb\char66 \char111 \char105 \char115 \ \char100 \char101 \ \char67 \char101 \char114 \char102 \ \mainfont{} etex,(18.83,2.47),0.0,p_label_mode_label);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \mainfont{} etex, (-148.42, 169.60), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \mainfont{} etex, (-157.11, 142.94), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \mainfont{} etex, (-165.46, 120.79), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char52 \mainfont{} etex, (-171.88, 122.65), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char53 \mainfont{} etex, (-152.06, 113.52), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char54 \mainfont{} etex, (-106.90, 91.14), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char55 \mainfont{} etex, (14.67, 112.01), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char56 \mainfont{} etex, (28.53, 93.17), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char57 \mainfont{} etex, (49.18, 65.10), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char48 \mainfont{} etex, (-0.12, 61.10), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char49 \mainfont{} etex, (-48.01, -2.08), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char50 \mainfont{} etex, (82.02, 50.36), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char51 \mainfont{} etex, (69.64, 54.86), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char52 \mainfont{} etex, (48.52, 31.53), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char53 \mainfont{} etex, (37.90, 22.28), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char54 \mainfont{} etex, (59.63, -4.04), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char55 \mainfont{} etex, (67.94, -46.66), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char56 \mainfont{} etex, (64.16, -75.53), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char49 \char57 \mainfont{} etex, (98.70, -107.81), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char48 \mainfont{} etex, (141.91, -128.29), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char49 \mainfont{} etex, (106.63, -188.03), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char50 \mainfont{} etex, (106.68, -208.73), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char50 \char51 \mainfont{} etex, (107.54, -224.42), 0.0, p_label_mode_debugstation);
drawoptions();
p_label.urt(btex \thstationname \thfb\char51 \char50 \mainfont{} etex, (202.72, -63.21), 0.0, p_label_mode_debugstation);
endfig;
beginfig(69);
s_northarrow(0);
endfig;
beginfig(70);
s_scalebar(25, 1, "\thfb\char109 \mainfont{}");
endfig;
background:=(0.00000,0.00000,0.10417,0.04000);
transparency:=false;
beginfig(71);
clean_legend_box;
drawoptions(withcolor (0.10000,0.88333,0.00000,0.40000));
p_station_temporary((0.5,0.5) inscale);
draw_legend_box;
endfig;
beginfig(72);
clean_legend_box;
drawoptions();
l_survey_cave(((-1,1) -- (0.8,0.6) -- (0,-1)) inscale);
drawoptions(withcolor HelpSymbolColor);
p_station_temporary((0.8,0.6) inscale);
drawoptions();
draw_legend_box;
endfig;
beginfig(73);
clean_legend_box;
drawoptions();
p_entrance((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(74);
clean_legend_box;
drawoptions();
l_mapconnection(((0.2,0.8) -- (0.8,0.2)) inscale)draw_legend_box;
endfig;
beginfig(75);
clean_legend_box;
drawoptions();
l_wall_bedrock(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(76);
clean_legend_box;
drawoptions();
l_wall_unsurveyed(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(77);
clean_legend_box;
drawoptions();
l_wall_presumed(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(78);
clean_legend_box;
drawoptions();
l_wall_pit(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(79);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((-.3,0.5) .. controls (.2,.6) and (.2,.6) .. (.3,.7) .. controls (.4,.8) and (.4,.8) .. (.5,1.4)) inscale);
drawoptions();
drawoptions(withcolor (0.00000,0.89744,0.33333,0.22000));
p_wallaltitude((0.2,0.6) inscale,(0.3,0.7) inscale,(0.4,0.8) inscale,btex \thwallaltitude \thfb\char49 \char53 \char49 \char48 \mainfont{} etex);
draw_legend_box;
endfig;
beginfig(80);
clean_legend_box;
drawoptions(withcolor (0.00000,0.50000,1.00000,0.00000));
p_label.rt(btex \thaltitude \thfb\char49 \char53 \char49 \char48 \mainfont{} etex,((0.3,0.5) inscale),0,p_label_mode_altitude);
draw_legend_box;
endfig;
beginfig(81);
clean_legend_box;
drawoptions();
p_airdraught((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(82);
clean_legend_box;
drawoptions();
p_airdraught_winter((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(83);
clean_legend_box;
drawoptions();
p_dig((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(84);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((0,.2){dir 30} .. {dir 0}(.5,.4)) inscale);
l_wall_bedrock(((.5,.6){dir 180} .. {dir 210}(0,.8)) inscale);
drawoptions();
drawoptions();
p_continuation((.6,.5) inscale,270.0,1.0,(0,1));
draw_legend_box;
endfig;
beginfig(85);
clean_legend_box;
drawoptions();
l_floormeander((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(86);
clean_legend_box;
drawoptions();
l_pit((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(87);
clean_legend_box;
drawoptions();
l_chimney((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(88);
clean_legend_box;
drawoptions();
l_gradient(((0.2,0.5) -- (0.8,0.5)) inscale);
draw_legend_box;
endfig;
beginfig(89);
clean_legend_box;
drawoptions();
l_contour((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale),-1);
draw_legend_box;
endfig;
beginfig(90);
clean_legend_box;
drawoptions();
l_slope((((.1,.35) .. (.5,.25) .. (.9,.35)) inscale),1,(0,-1,1u),(2,-1,1u));
draw_legend_box;
endfig;
beginfig(91);
clean_legend_box;
drawoptions();
l_rockborder(((.16,.36) -- (.61,.21) -- (.91,.46) -- (.84,.78) -- (.38,.86) -- (.20,.55) -- cycle) inscale)draw_legend_box;
endfig;
beginfig(92);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_rockborder(((.16,.36) -- (.61,.21) -- (.91,.46) -- (.84,.78) -- (.38,.86) -- (.20,.55) -- cycle) inscale)drawoptions();
drawoptions();
l_rockedge(((.16,.36) -- (.42,.62) -- (.38,.86) -- (.42,.62) -- (.6,.55) -- (.61,.21) -- (.6,.55) -- (.84,.78)) inscale)draw_legend_box;
endfig;
beginfig(93);
clean_legend_box;
drawoptions();
p_blocks((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(94);
clean_legend_box;
drawoptions();
p_debris((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(95);
clean_legend_box;
drawoptions();
l_border_visible((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(96);
clean_legend_box;
drawoptions();
a_water(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(97);
clean_legend_box;
drawoptions();
a_clay(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(98);
clean_legend_box;
drawoptions();
a_debris(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(99);
clean_legend_box;
drawoptions(withcolor (0.83000,0.54000,0.00000,0.00000));
l_waterflow_permanent(((0.2,0.8) -- (0.8,0.2)) inscale);
draw_legend_box;
endfig;
beginfig(100);
clean_legend_box;
drawoptions();
p_stalactite((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(101);
clean_legend_box;
drawoptions();
p_stalactites((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(102);
clean_legend_box;
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_stalagmite((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(103);
clean_legend_box;
drawoptions();
p_stalagmites((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(104);
clean_legend_box;
drawoptions();
p_gypsum((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(105);
clean_legend_box;
drawoptions(withcolor (0.00000,0.40000,0.80000,0.00000));
p_rimstonedam((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(106);
clean_legend_box;
drawoptions();
p_rimstonepool((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
end;
