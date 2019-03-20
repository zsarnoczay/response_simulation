#===============================================================================
#
#                                     CONSTANTS AND BASIC FUNCTIONS FOR MODELING
#
#                                                        author: Adam Zsarnóczay
#                                                        created:  2013. 09. 03.
#
#                                                        contributors:           
#                                                             Luis Macedo @ FEUP
#
# Copyright (c) 2013 Adam Zsarnóczay
# 
# Redistribution and use of this file in source and binary forms, with or 
# without modification, are permitted provided that the following conditions 
# are met:
#
# 1. Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, 
# this list of conditions and the following disclaimer in the documentation 
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors 
# may be used to endorse or promote products derived from this software without 
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
# You should have received a copy of the BSD 3-Clause License along with 
# this file. If not, see <http://www.opensource.org/licenses/>.
#_______________________________________________________________________________

# define constants
set LunitTXT "meter"
set FunitTXT "Newton"
set TunitTXT "sec"
set Ubig 1e10
set Usmall [expr 1/$Ubig]
set g 9.80665
set pi [expr 2*asin(1.0)]
#define metric units
set m 1.;
set cm 0.01;
set mm 0.001;
set m2 1.;
set cm2 1e-4;
set mm2 1e-6;
set m3 1.;
set m4 1.;
set cm4 1e-8;
set mm4 1e-12;
set N 1.;
set kN 1000.;
set sec 1.;
set MPa 1e6;
set GPa 1e9;
#define imperial units
set in [expr $m*0.0254]
set ft [expr $m*0.3048]
set in2 [expr $mm2*645.16]
set ft2 [expr $m2*0.092903]
set in4 [expr $cm4*41.623143]
set ft4 [expr $m4*0.008631]
set kip [expr $kN*4.448222]
set ksi [expr $MPa*6.894757]

#===============================================================================
#
#                                                            MATERIAL PROPERTIES
#
#===============================================================================
#_______________________________________________________________________________
#             UR - artificial ultra rigid material with linear elastic behaviour
proc URmat {matID} {
  set UR_E   [expr 10000*1e9]
  uniaxialMaterial Elastic $matID $UR_E
}

#_______________________________________________________________________________
#                                                             BRB - BRB material
proc BRBmat { matID A_y sF dF f_yd g_ov pushover} {

  set matBRB $matID;
  set matSteel4 [expr $matID*10];

  set Fmulti [expr (0.14 + 0.4*($g_ov-1.1))/$dF];
  set f_A [expr sqrt($A_y/0.005)]

  if {$pushover == 0} { 
    set f_y  [expr $g_ov*$f_yd];          # yielding point
    set f_u  [expr 1.65*$f_y];            # ultimate load bearing capacity
    set f_uc [expr 2.4*$f_y];             # ultimate load bearing capacity
    set E_0  [expr $sF*210*1e9];          # Young modulus
    #kinematic tension
    set b_k 0.005;                        # strain-hardening ratio
    set R_0 25.0;                         # control the transition from elastic to plastic branches
    set r_1 0.91;
    set r_2 0.1;
    set R_u 2.0;
    #           compression
    set b_kc [expr (3.0-0.5*$f_A)/100.0]; # strain-hardening ratio
    set R_0c 25.0;                        # control the transition from elastic to plastic branches
    set r_1c 0.89;
    set r_2c 0.02;
    set R_uc 2.0;
    #isotropic
    set l_yp 1.0;
    #          tension
    set b_i [expr (0.3-0.05*$f_A)/100.0]; # total accumulated plastic strain dependent isotropic hardening
    set R_i 3.0;
    set rho_i [expr 0.25+0.05*$f_A];
    set b_l   0.0001;
    #          compression
    set b_ic [expr (0.5+0.1*$f_A)/100.0]; # total accumulated plastic strain dependent isotropic hardening
    set R_ic 3.0;
    set rho_ic [expr 0.25+0.05*$f_A];
    set b_lc [expr (0.04 - 0.007*$f_A)/100.0];

    uniaxialMaterial Steel4 $matSteel4 $f_y $E_0 \
                                      -asym \
                                      -kin $b_k $R_0 $r_1 $r_2 $b_kc $R_0c $r_1c $r_2c \
                                      -iso $b_i $rho_i $b_l $R_i $l_yp $b_ic $rho_ic $b_lc $R_i \
                                      -ult $f_u $R_u $f_uc $R_uc                                     

    uniaxialMaterial Fatigue $matBRB $matSteel4 -E0 $Fmulti -m -0.400
  }

  if {$pushover == 1} {
    # calibrated to match the SSE BRB backbone
    set f_y  [expr $g_ov*$f_yd];          # yielding point
    set E_0  [expr $sF*210*1e9];          # Young modulus C800B
    #kinematic
    set b_k  0.045;                       # strain-hardening ratio
    set b_kc 0.065;                       # strain-hardening ratio
    set R_0 25.0;                         # control the transition from elastic to plastic branches
    set r_1 0.01;
    set r_2 0.15;

    set eps_limit [expr 0.06/$dF]

    uniaxialMaterial Steel4 $matSteel4 $f_y $E_0 \
                                     -asym \
                                     -kin $b_k $R_0 $r_1 $r_2 $b_kc $R_0 $r_1 $r_2 \
                                     -ult [expr $f_y*1.65] 5.0 [expr $f_y*2.50] 5.0
    uniaxialMaterial Fatigue $matBRB $matSteel4 -E0 $Fmulti -m -0.400 -min [expr -$eps_limit] \
                                                                      -max $eps_limit
  }
}

#_______________________________________________________________________________
#                                Ibarra-Medina-Krawinkler plastic hinge material
#                                           setup based on the work of D. Lignos
proc IKmat { matID f_y n L geom geomUnit M_Rd R dir f_yk} {
  set Es [expr 210*1e9];
  set b_f [expr [dict get $geom b_f]*$geomUnit]
  set t_w [expr [dict get $geom t_w]*$geomUnit]
  set t_f [expr [dict get $geom t_f]*$geomUnit]
  set h_w [expr [dict get $geom h_w]*$geomUnit - 2 * $t_f]
  if {$dir == 0} {
    set I [expr [dict get $geom I_y]*pow($geomUnit,4)]
    set I [expr $I - 2 * $b_f * $R * ($t_f * pow(($h_w + $t_f) / 2.0, 2) + pow($t_f, 3) / 12.0)]
    #reduction in cross-section modulus due to reduced flange size is NOT considered
    set W_pl [expr [dict get $geom W_pl_y] * pow($geomUnit,3)]
  }
  if {$dir == 90} {
    set I [expr [dict get $geom I_z]*pow($geomUnit,4)]
    set W_pl [expr [dict get $geom W_pl_z] * pow($geomUnit,3)]
  }
  if {$M_Rd > 1.0} {
    set M_y [expr $M_Rd * $f_y / $f_yk]
  } else {
    set M_y [expr $W_pl * $M_Rd * $f_y]
  }

  set K_mem [expr 6*$Es*$I/$L]
  set K_s [expr ($n+1.0)*$K_mem]

  # MyMp = 1.00 is justified by the increased yield strength of the material
  set MyMyp 1.00
  set My_Plus [expr $M_y*$MyMyp]
  set My_Neg  [expr -$M_y*$MyMyp]
  set McMy 1.11

  set theta_p_Plus [expr 0.0865*pow(($h_w+2*$t_f)/$t_w,-0.365) \
                               *pow($b_f/(2*$t_f),-0.14)\
                               *pow($L/$h_w,0.34)\
                               *pow($h_w*1000.0/533.0,-0.721)\
                               *pow($f_y/(355*1e6),-0.23)]
  set theta_p_Neg $theta_p_Plus
  set theta_pc_Plus [expr 5.63*pow(($h_w+2*$t_f)/$t_w,-0.565) \
                              *pow($b_f/(2*$t_f),-0.8)\
                              *pow($h_w*1000.0/533.0,-0.28)\
                              *pow($f_y/(355*1e6),-0.43)]
  set theta_pc_Neg $theta_pc_Plus

  set lambda [expr 495*pow(($h_w+2*$t_f)/$t_w,-1.34) \
                      *pow($b_f/(2*$t_f),-0.595)\
                      *pow($f_y/(355*1e6),-0.36)]
  set lambda_S $lambda
  set lambda_C $lambda
  set lambda_A $lambda
  set lambda_K $lambda

  set as [expr ($My_Plus*($McMy-1.0)) / ($n*$K_mem*$theta_p_Plus)];
  set as_Plus [expr ($n+1.0)*($as)/(1.0+$n*(1.0-$as))];
  set as_Neg $as_Plus

  # the following are default and recommended values
  # The original theta_u_Plus = 0.06 was modified based on Zareian's paper
  set theta_u_Plus 0.2
  set theta_u_Neg  0.2
  set c_S 1.0
  set c_C 1.0
  set c_A 1.0
  set c_K 1.0
  set Res_Pos 0.4
  set Res_Neg 0.4
  set D_Plus 1.0
  set D_Neg 1.0

  uniaxialMaterial Bilin $matID $K_s \
                         $as_Plus $as_Neg $My_Plus $My_Neg \
                         $lambda_S $lambda_C $lambda_A $lambda_K \
                         $c_S $c_C $c_A $c_K \
                         $theta_p_Plus $theta_p_Neg $theta_pc_Plus $theta_pc_Neg \
                         $Res_Pos $Res_Neg \
                         $theta_u_Plus $theta_u_Neg $D_Plus $D_Neg
}

#===============================================================================
#
#                                                                       SECTIONS
#
#===============================================================================
#function to generate a custom I section from fibers
proc genFiberI { secID matID geom geomUnit} {

  set pi [expr 2.0*asin(1.0)]; 

  set h  [expr [dict get $geom h_w]*$geomUnit]
  set b1 [expr [dict get $geom b_f]*$geomUnit]
  set tw [expr [dict get $geom t_w]*$geomUnit]
  set tf [expr [dict get $geom t_f]*$geomUnit]
  set r  [expr [dict get $geom r  ]*$geomUnit]

  if {$h < 5.0} {
    # regular I sections

    set hw [expr $h - 2 * $tf]

    #set nfh 10
    #set nfh 5
    set nfh 2
    set nfb 1
    #set nftf 24
    #set nftf 12
    #set nftf 4
    set nftf 2
    set nftw 1

    set y1 [expr -$b1/2]
    set y2 [expr  $b1/2]
    set y3 [expr  $tw/2]
    set y4 [expr -$tw/2]
    set y5 [expr  -$b1/2]
    set y6 [expr  $b1/2]

    set z1 [expr  $hw/2]
    set z2 [expr  $h/2]
    set z3 [expr  $hw/2]
    set z4 [expr  -$hw/2]
    set z5 [expr  -$h/2]
    set z6 [expr  -$hw/2]

    #calculate the fillet attributes
    set A_fillet [expr $r*$r*(1.0-$pi/4.0)]
    set c_fillet [expr $r*(10-3*$pi)/(12-3*$pi)]

    #strong-axis bending, local Z axis parallel with global X axis
    section fiberSec $secID {
      #three patches for the main plates
      patch rect $matID $nftf $nfb $z1 $y1 $z2 $y2;     #upper flange
      patch rect $matID $nftf $nfb $z3 $y3 $z4 $y4;     #lower flange
      patch rect $matID $nfh  $nftw $z5 $y5 $z6 $y6;     #web
      #four fibers for the fillets
      fiber [expr $z3 - $c_fillet]   [expr $y3 + $c_fillet]   $A_fillet  $matID;     #upper right fillet
      fiber [expr $z3 - $c_fillet]   [expr $y4 - $c_fillet]   $A_fillet  $matID;     #upper left fillet
      fiber [expr $z4 + $c_fillet]   [expr $y3 + $c_fillet]   $A_fillet  $matID;     #lower right fillet
      fiber [expr $z4 + $c_fillet]   [expr $y4 - $c_fillet]   $A_fillet  $matID;     #lower left fillet
    }

    #weak-axis bending, local Y axis parallel with global X axis
    #section fiberSec $secID {
    #    patch rect $matID $nfb $nft $y1 $z1 $y2 $z2
    #    patch rect $matID $nft $nfb $y3 $z3 $y4 $z4
    #    patch rect $matID $nfh $nft $y5 $z5 $y6 $z6
    #}
  } else {
    # cruciform sections (made of two I sections)

    set h [expr $h - 5.0]

    set hw [expr $h - 2 * $tf]

    #set nfh 10
    set nfh 2
    set nfb 1
    #set nftf 12
    #set nftf 4
    set nftf 2
    set nftw 1

    set a1 [expr -$h /2]
    set a2 [expr -$hw/2]
    set a3 [expr -$b1/2]
    set a4 [expr -$tw/2]
    set a5 [expr  $tw/2]
    set a6 [expr  $b1/2]
    set a7 [expr  $hw/2]
    set a8 [expr  $h /2]

    section fiberSec $secID {
      patch rect $matID $nftf $nfb  $a1 $a3 $a2 $a6
      patch rect $matID $nftf $nfb  $a7 $a3 $a8 $a6
      patch rect $matID $nftf $nftw $a2 $a4 $a7 $a5
      patch rect $matID $nftf $nftw $a3 $a7 $a6 $a8
      patch rect $matID $nftf $nftw $a3 $a1 $a6 $a2
      patch rect $matID $nfh  $nfb  $a4 $a2 $a5 $a4
      patch rect $matID $nfh  $nfb  $a4 $a5 $a5 $a7
    }
  }
}

#function to generate a custom RHS section from fibers
proc genFiberRHS { secID matID h b t} {
  set hw [expr $h - 2 * $t]
  set bw [expr $b - 2 * $t]
  set nfh 10
  set nfh 5
  set nfh 2
  set nfb 1
  set nft1 10
  set nft1 5
  set nft1 3
  set nft2 1
  set y1 [expr -$h/2]
  set y2 [expr -$hw/2]
  set y3 [expr $hw/2]
  set y4 [expr $h/2]
  set z1 [expr -$b/2]
  set z2 [expr -$bw/2]
  set z3 [expr $bw/2]
  set z4 [expr $b/2]
  section fiberSec $secID {
    patch rect $matID $nft1 $nfb $y1 $z1 $y2 $z4
    patch rect $matID $nfh $nft2 $y2 $z1 $y3 $z2
    patch rect $matID $nfh $nft2 $y2 $z3 $y3 $z4
    patch rect $matID $nft1 $nfb $y3 $z1 $y4 $z4
  }
}

#create a dictionary of European I section data
set secI [dict create]

dict set secI HEA100 {h_w  96 b_f 100 t_w  5.0 t_f  8.0 r 12.0 A  2120 I_y    3490000 I_z   1340000 W_el_y   72800 W_el_z  26800 W_pl_y    83010 W_pl_z   41140}
dict set secI HEA120 {h_w 114 b_f 120 t_w  5.0 t_f  8.0 r 12.0 A  2530 I_y    6060000 I_z   2310000 W_el_y  106000 W_el_z  38500 W_pl_y   119500 W_pl_z   58850}
dict set secI HEA140 {h_w 133 b_f 140 t_w  5.5 t_f  8.5 r 12.0 A  3140 I_y   10300000 I_z   3890000 W_el_y  155000 W_el_z  55600 W_pl_y   173500 W_pl_z   84850}
dict set secI HEA160 {h_w 152 b_f 160 t_w  6.0 t_f  9.0 r 15.0 A  3880 I_y   16700000 I_z   6160000 W_el_y  220000 W_el_z  76900 W_pl_y   245100 W_pl_z  117600}
dict set secI HEA180 {h_w 171 b_f 180 t_w  6.0 t_f  9.5 r 15.0 A  4530 I_y   24100000 I_z   9250000 W_el_y  294000 W_el_z 103000 W_pl_y   324900 W_pl_z  156500}
dict set secI HEA200 {h_w 190 b_f 200 t_w  6.5 t_f 10.0 r 18.0 A  5380 I_y   36900000 I_z  13400000 W_el_y  389000 W_el_z 134000 W_pl_y   429500 W_pl_z  203800}
dict set secI HEA220 {h_w 210 b_f 220 t_w  7.0 t_f 11.0 r 18.0 A  6430 I_y   54100000 I_z  19500000 W_el_y  515000 W_el_z 178000 W_pl_y   568500 W_pl_z  270600}
dict set secI HEA240 {h_w 230 b_f 240 t_w  7.5 t_f 12.0 r 21.0 A  7680 I_y   77600000 I_z  27700000 W_el_y  675000 W_el_z 231000 W_pl_y   744600 W_pl_z  351700}
dict set secI HEA260 {h_w 250 b_f 260 t_w  7.5 t_f 12.5 r 24.0 A  8680 I_y  104500000 I_z  36700000 W_el_y  836000 W_el_z 282000 W_pl_y   919800 W_pl_z  430200}
dict set secI HEA280 {h_w 270 b_f 280 t_w  8.0 t_f 13.0 r 24.0 A  9730 I_y  136700000 I_z  47600000 W_el_y 1010000 W_el_z 340000 W_pl_y  1112000 W_pl_z  518100}
dict set secI HEA300 {h_w 290 b_f 300 t_w  8.5 t_f 14.0 r 27.0 A 11200 I_y  182600000 I_z  63100000 W_el_y 1260000 W_el_z 421000 W_pl_y  1383000 W_pl_z  641200}
dict set secI HEA320 {h_w 310 b_f 300 t_w  9.0 t_f 15.5 r 27.0 A 12400 I_y  229300000 I_z  69900000 W_el_y 1480000 W_el_z 466000 W_pl_y  1628000 W_pl_z  709700}
dict set secI HEA340 {h_w 330 b_f 300 t_w  9.5 t_f 16.5 r 27.0 A 13300 I_y  276900000 I_z  74400000 W_el_y 1680000 W_el_z 496000 W_pl_y  1850000 W_pl_z  755900}
dict set secI HEA360 {h_w 350 b_f 300 t_w 10.0 t_f 17.5 r 27.0 A 14300 I_y  330900000 I_z  78900000 W_el_y 1890000 W_el_z 526000 W_pl_y  2088000 W_pl_z  802300}
dict set secI HEA400 {h_w 390 b_f 300 t_w 11.0 t_f 19.0 r 27.0 A 15900 I_y  450700000 I_z  85600000 W_el_y 2310000 W_el_z 571000 W_pl_y  2562000 W_pl_z  872900}
dict set secI HEA450 {h_w 440 b_f 300 t_w 11.5 t_f 21.0 r 27.0 A 17800 I_y  637200000 I_z  94700000 W_el_y 2900000 W_el_z 631000 W_pl_y  3216000 W_pl_z  965500}
dict set secI HEA500 {h_w 490 b_f 300 t_w 12.0 t_f 23.0 r 27.0 A 19800 I_y  869700000 I_z 103700000 W_el_y 3550000 W_el_z 691000 W_pl_y  3949000 W_pl_z 1059000}
dict set secI HEA550 {h_w 540 b_f 300 t_w 12.5 t_f 24.0 r 27.0 A 21200 I_y 1119000000 I_z 108200000 W_el_y 4150000 W_el_z 721000 W_pl_y  4622000 W_pl_z 1107000}
dict set secI HEA600 {h_w 590 b_f 300 t_w 13.0 t_f 25.0 r 27.0 A 22600 I_y 1412000000 I_z 112700000 W_el_y 4790000 W_el_z 751000 W_pl_y  5350000 W_pl_z 1156000}
dict set secI HEA650 {h_w 640 b_f 300 t_w 13.5 t_f 26.0 r 27.0 A 24200 I_y 1752000000 I_z 117200000 W_el_y 5470000 W_el_z 782000 W_pl_y  6136000 W_pl_z 1205000}
dict set secI HEA700 {h_w 690 b_f 300 t_w 14.5 t_f 27.0 r 27.0 A 26000 I_y 2153000000 I_z 121800000 W_el_y 6240000 W_el_z 812000 W_pl_y  7032000 W_pl_z 1257000}
dict set secI HEA800 {h_w 790 b_f 300 t_w 15.0 t_f 28.0 r 30.0 A 28600 I_y 3034000000 I_z 126400000 W_el_y 7680000 W_el_z 843000 W_pl_y  8699000 W_pl_z 1312000}
dict set secI HEA900 {h_w 890 b_f 300 t_w 16.0 t_f 30.0 r 30.0 A 32100 I_y 4221000000 I_z 135500000 W_el_y 9480000 W_el_z 903000 W_pl_y 10810000 W_pl_z 1414000}

dict set secI HEB100 {h_w 100 b_f 100 t_w  6.0 t_f 10.0 r 12.0 A  2600 I_y    4500000 I_z   1670000 W_el_y    88900 W_el_z   33500 W_pl_y   104200 W_pl_z   51420}
dict set secI HEB120 {h_w 120 b_f 120 t_w  6.5 t_f 11.0 r 12.0 A  3400 I_y    8640000 I_z   3180000 W_el_y   144000 W_el_z   52900 W_pl_y   165200 W_pl_z   80970}
dict set secI HEB140 {h_w 140 b_f 140 t_w  7.0 t_f 12.0 r 12.0 A  4300 I_y   15100000 I_z   5500000 W_el_y   216000 W_el_z   78500 W_pl_y   245400 W_pl_z  119800}
dict set secI HEB160 {h_w 160 b_f 160 t_w  8.0 t_f 13.0 r 15.0 A  5430 I_y   24900000 I_z   8890000 W_el_y   311000 W_el_z  111000 W_pl_y   354000 W_pl_z  170000}
dict set secI HEB180 {h_w 180 b_f 180 t_w  8.5 t_f 14.0 r 15.0 A  6530 I_y   38300000 I_z  13600000 W_el_y   426000 W_el_z  151000 W_pl_y   481400 W_pl_z  231000}
dict set secI HEB200 {h_w 200 b_f 200 t_w  9.0 t_f 15.0 r 18.0 A  7810 I_y   57000000 I_z  20000000 W_el_y   570000 W_el_z  200000 W_pl_y   642500 W_pl_z  304800}
dict set secI HEB220 {h_w 220 b_f 220 t_w  9.5 t_f 16.0 r 18.0 A  9100 I_y   80900000 I_z  28400000 W_el_y   736000 W_el_z  258000 W_pl_y   827000 W_pl_z  393900}
dict set secI HEB240 {h_w 240 b_f 240 t_w 10.0 t_f 17.0 r 21.0 A 10600 I_y  112600000 I_z  39200000 W_el_y   938000 W_el_z  327000 W_pl_y  1053000 W_pl_z  498400}
dict set secI HEB260 {h_w 260 b_f 260 t_w 10.0 t_f 17.5 r 24.0 A 11800 I_y  149200000 I_z  51300000 W_el_y  1150000 W_el_z  395000 W_pl_y  1283000 W_pl_z  602200}
dict set secI HEB280 {h_w 280 b_f 280 t_w 10.5 t_f 18.0 r 24.0 A 13100 I_y  192700000 I_z  65900000 W_el_y  1380000 W_el_z  471000 W_pl_y  1534000 W_pl_z  717600}
dict set secI HEB300 {h_w 300 b_f 300 t_w 11.0 t_f 19.0 r 27.0 A 14900 I_y  251700000 I_z  85600000 W_el_y  1680000 W_el_z  571000 W_pl_y  1869000 W_pl_z  870100}
dict set secI HEB320 {h_w 320 b_f 300 t_w 11.5 t_f 20.5 r 27.0 A 16100 I_y  308200000 I_z  92400000 W_el_y  1930000 W_el_z  616000 W_pl_y  2149000 W_pl_z  939100}
dict set secI HEB340 {h_w 340 b_f 300 t_w 12.0 t_f 21.5 r 27.0 A 17100 I_y  366600000 I_z  96900000 W_el_y  2160000 W_el_z  646000 W_pl_y  2408000 W_pl_z  985700}
dict set secI HEB360 {h_w 360 b_f 300 t_w 12.5 t_f 22.5 r 27.0 A 18100 I_y  431900000 I_z 101400000 W_el_y  2400000 W_el_z  676000 W_pl_y  2683000 W_pl_z 1032000}
dict set secI HEB400 {h_w 400 b_f 300 t_w 13.5 t_f 24.0 r 27.0 A 19800 I_y  576800000 I_z 108200000 W_el_y  2880000 W_el_z  721000 W_pl_y  3232000 W_pl_z 1104000}
dict set secI HEB450 {h_w 450 b_f 300 t_w 14.0 t_f 26.0 r 27.0 A 21800 I_y  798900000 I_z 117200000 W_el_y  3550000 W_el_z  781000 W_pl_y  3982000 W_pl_z 1198000}
dict set secI HEB500 {h_w 500 b_f 300 t_w 14.5 t_f 28.0 r 27.0 A 23900 I_y 1072000000 I_z 126200000 W_el_y  4290000 W_el_z  842000 W_pl_y  4815000 W_pl_z 1292000}
dict set secI HEB550 {h_w 550 b_f 300 t_w 15.0 t_f 29.0 r 27.0 A 25400 I_y 1367000000 I_z 130800000 W_el_y  4970000 W_el_z  872000 W_pl_y  5591000 W_pl_z 1341000}
dict set secI HEB600 {h_w 600 b_f 300 t_w 15.5 t_f 30.0 r 27.0 A 27000 I_y 1710000000 I_z 135300000 W_el_y  5700000 W_el_z  902000 W_pl_y  6425000 W_pl_z 1391000}
dict set secI HEB650 {h_w 650 b_f 300 t_w 16.0 t_f 31.0 r 27.0 A 28600 I_y 2106000000 I_z 139800000 W_el_y  6480000 W_el_z  932000 W_pl_y  7320000 W_pl_z 1441000}
dict set secI HEB700 {h_w 700 b_f 300 t_w 17.0 t_f 32.0 r 27.0 A 30600 I_y 2569000000 I_z 144400000 W_el_y  7340000 W_el_z  963000 W_pl_y  8327000 W_pl_z 1495000}
dict set secI HEB800 {h_w 800 b_f 300 t_w 17.5 t_f 33.0 r 30.0 A 33400 I_y 3591000000 I_z 149000000 W_el_y  8980000 W_el_z  994000 W_pl_y 10230000 W_pl_z 1553000}
dict set secI HEB900 {h_w 900 b_f 300 t_w 18.5 t_f 35.0 r 30.0 A 37100 I_y 4941000000 I_z 158200000 W_el_y 10980000 W_el_z 1050000 W_pl_y 12580000 W_pl_z 1658000}
dict set secI HEB1000 {h_w 1000 b_f 300 t_w 19.0 t_f 36.0 r 30.0 A 40000 I_y 6447000000 I_z 162800000 W_el_y 12890000 W_el_z 1090000 W_pl_y 14860000 W_pl_z 1716000}

dict set secI HEM100 {h_w 120 b_f 106 t_w 12.0 t_f 20.0 r 12.0 A  5320 I_y   11400000 I_z   3990000 W_el_y   190000 W_el_z   75300 W_pl_y   235800 W_pl_z  116300}
dict set secI HEM120 {h_w 140 b_f 126 t_w 12.5 t_f 21.0 r 12.0 A  6640 I_y   20200000 I_z   7030000 W_el_y   288000 W_el_z  112000 W_pl_y   350600 W_pl_z  171600}
dict set secI HEM140 {h_w 160 b_f 146 t_w 13.0 t_f 22.0 r 12.0 A  8060 I_y   32900000 I_z  11400000 W_el_y   411000 W_el_z  157000 W_pl_y   493800 W_pl_z  240500}
dict set secI HEM160 {h_w 180 b_f 166 t_w 14.0 t_f 23.0 r 15.0 A  9710 I_y   51000000 I_z  17600000 W_el_y   566000 W_el_z  212000 W_pl_y   674600 W_pl_z  325500}
dict set secI HEM180 {h_w 200 b_f 186 t_w 14.5 t_f 24.0 r 15.0 A 11300 I_y   74800000 I_z  25800000 W_el_y   748000 W_el_z  277000 W_pl_y   883400 W_pl_z  425200}
dict set secI HEM200 {h_w 220 b_f 206 t_w 15.0 t_f 25.0 r 18.0 A 13100 I_y  106400000 I_z  36500000 W_el_y   967000 W_el_z  354000 W_pl_y  1135000 W_pl_z  543200}
dict set secI HEM220 {h_w 240 b_f 226 t_w 15.5 t_f 26.0 r 18.0 A 14900 I_y  146000000 I_z  50100000 W_el_y  1220000 W_el_z  444000 W_pl_y  1419000 W_pl_z  678600}
dict set secI HEM240 {h_w 270 b_f 248 t_w 18.0 t_f 32.0 r 21.0 A 20000 I_y  242900000 I_z  81500000 W_el_y  1800000 W_el_z  657000 W_pl_y  2117000 W_pl_z 1006000}
dict set secI HEM260 {h_w 290 b_f 268 t_w 18.0 t_f 32.5 r 24.0 A 22000 I_y  313100000 I_z 104500000 W_el_y  2160000 W_el_z  780000 W_pl_y  2524000 W_pl_z 1192000}
dict set secI HEM280 {h_w 310 b_f 288 t_w 18.5 t_f 33.0 r 24.0 A 24000 I_y  395500000 I_z 131600000 W_el_y  2550000 W_el_z  914000 W_pl_y  2966000 W_pl_z 1397000}
dict set secI HEM300 {h_w 340 b_f 310 t_w 21.0 t_f 39.0 r 27.0 A 30300 I_y  592000000 I_z 194000000 W_el_y  3480000 W_el_z 1250000 W_pl_y  4078000 W_pl_z 1913000}
dict set secI HEM320 {h_w 359 b_f 309 t_w 21.0 t_f 40.0 r 27.0 A 31200 I_y  681300000 I_z 197100000 W_el_y  3800000 W_el_z 1280000 W_pl_y  4435000 W_pl_z 1951000}
dict set secI HEM340 {h_w 377 b_f 309 t_w 21.0 t_f 40.0 r 27.0 A 31600 I_y  763700000 I_z 197100000 W_el_y  4050000 W_el_z 1280000 W_pl_y  4718000 W_pl_z 1953000}
dict set secI HEM360 {h_w 395 b_f 308 t_w 21.0 t_f 40.0 r 27.0 A 31900 I_y  848700000 I_z 195200000 W_el_y  4300000 W_el_z 1270000 W_pl_y  4989000 W_pl_z 1942000}
dict set secI HEM400 {h_w 432 b_f 307 t_w 21.0 t_f 40.0 r 27.0 A 32600 I_y 1041000000 I_z 193300000 W_el_y  4820000 W_el_z 1260000 W_pl_y  5571000 W_pl_z 1934000}
dict set secI HEM450 {h_w 478 b_f 307 t_w 21.0 t_f 40.0 r 27.0 A 33500 I_y 1315000000 I_z 193400000 W_el_y  5500000 W_el_z 1260000 W_pl_y  6331000 W_pl_z 1939000}
dict set secI HEM500 {h_w 524 b_f 306 t_w 21.0 t_f 40.0 r 27.0 A 34400 I_y 1619000000 I_z 191500000 W_el_y  6180000 W_el_z 1250000 W_pl_y  7094000 W_pl_z 1932000}
dict set secI HEM550 {h_w 572 b_f 306 t_w 21.0 t_f 40.0 r 27.0 A 35400 I_y 1980000000 I_z 191800000 W_el_y  6920000 W_el_z 1250000 W_pl_y  7933000 W_pl_z 1937000}
dict set secI HEM600 {h_w 620 b_f 305 t_w 21.0 t_f 40.0 r 27.0 A 36400 I_y 2374000000 I_z 189700000 W_el_y  7660000 W_el_z 1240000 W_pl_y  8772000 W_pl_z 1930000}
dict set secI HEM650 {h_w 668 b_f 305 t_w 21.0 t_f 40.0 r 27.0 A 37400 I_y 2817000000 I_z 189800000 W_el_y  8430000 W_el_z 1240000 W_pl_y  9657000 W_pl_z 1936000}
dict set secI HEM700 {h_w 716 b_f 304 t_w 21.0 t_f 40.0 r 27.0 A 38300 I_y 3293000000 I_z 188000000 W_el_y  9200000 W_el_z 1240000 W_pl_y 10540000 W_pl_z 1929000}
dict set secI HEM800 {h_w 814 b_f 303 t_w 21.0 t_f 40.0 r 30.0 A 40400 I_y 4426000000 I_z 185300000 W_el_y 10870000 W_el_z 1230000 W_pl_y 12490000 W_pl_z 1930000}
dict set secI HEM900 {h_w 910 b_f 302 t_w 21.0 t_f 40.0 r 30.0 A 42400 I_y 5704000000 I_z 184500000 W_el_y 12540000 W_el_z 1220000 W_pl_y 14440000 W_pl_z 1929000}

dict set secI HE400x299 {h_w 444 b_f 309 t_w 25.5 t_f 46.0 r 27.0 A 38032 I_y 1241645000 I_z 226919300 W_el_y  5592996 W_el_z 1468733 W_pl_y  6553906 W_pl_z 2265103}
dict set secI HE400x347 {h_w 458 b_f 313 t_w 29.5 t_f 53.0 r 27.0 A 44190 I_y 1493665000 I_z 271909200 W_el_y  6522555 W_el_z 1737439 W_pl_y  7739183 W_pl_z 2685836}
dict set secI HE450x436 {h_w 526 b_f 319 t_w 35.5 t_f 64.0 r 27.0 A 55589 I_y 2402704000 I_z 348115000 W_el_y  9135758 W_el_z 2182539 W_pl_y 10959330 W_pl_z 3396709}

dict set secI HEAA100 {h_w  91 b_f 100 t_w 4.2 t_f 5.5 r 12.0 A 1560 I_y  2365000 I_z   921000 W_el_y   52000 W_el_z  18400 W_pl_y  58360 W_pl_z  28440}
dict set secI HEAA120 {h_w 109 b_f 120 t_w 4.2 t_f 5.5 r 12.0 A 1860 I_y  4134000 I_z  1590000 W_el_y   75900 W_el_z  26500 W_pl_y  84120 W_pl_z  40620}
dict set secI HEAA140 {h_w 128 b_f 140 t_w 4.3 t_f 6.0 r 12.0 A 2300 I_y  7195000 I_z  2750000 W_el_y  112000 W_el_z  39300 W_pl_y 123800 W_pl_z  59930}
dict set secI HEAA160 {h_w 148 b_f 160 t_w 4.5 t_f 7.0 r 15.0 A 3040 I_y 12830000 I_z  4790000 W_el_y  173000 W_el_z  59900 W_pl_y 190400 W_pl_z  91360}
dict set secI HEAA180 {h_w 167 b_f 180 t_w 5 7.t_f 5.0 r 15.0 A 3630 I_y 19670000 I_z  7300000 W_el_y  236000 W_el_z  81100 W_pl_y 258200 W_pl_z 123600}
dict set secI HEAA200 {h_w 186 b_f 200 t_w 5.5 t_f 8.0 r 18.0 A 4410 I_y 29440000 I_z 10680000 W_el_y  317000 W_el_z 107000 W_pl_y 347100 W_pl_z 163200}
dict set secI HEAA220 {h_w 205 b_f 220 t_w 6.0 t_f 8.5 r 18.0 A 5150 I_y 41700000 I_z 15100000 W_el_y  407000 W_el_z 137000 W_pl_y 445500 W_pl_z 209300}
dict set secI HEAA240 {h_w 224 b_f 240 t_w 6.5 t_f 9.0 r 21.0 A 6040 I_y 58350000 I_z 20770000 W_el_y  521000 W_el_z 173000 W_pl_y 570600 W_pl_z 264400}
dict set secI HEAA260 {h_w 244 b_f 260 t_w 6.5 t_f 9.5 r 24.0 A 6900 I_y 79810000 I_z 27880000 W_el_y  654000 W_el_z 215000 W_pl_y 714500 W_pl_z 327700}

dict set secI  IPE80 {h_w  80 b_f  46 t_w  3.8 t_f  5.2 r  5.0 A   764 I_y    801000 I_z    84900 W_el_y   20000 W_el_z   3690 W_pl_y   23200 W_pl_z   5800}
dict set secI IPE100 {h_w 100 b_f  55 t_w  4.1 t_f  5.7 r  7.0 A  1030 I_y   1710000 I_z   159000 W_el_y   34200 W_el_z   5790 W_pl_y   39400 W_pl_z   9200}
dict set secI IPE120 {h_w 120 b_f  64 t_w  4.4 t_f  6.3 r  7.0 A  1320 I_y   3180000 I_z   277000 W_el_y   53000 W_el_z   8650 W_pl_y   60700 W_pl_z  13600}
dict set secI IPE140 {h_w 140 b_f  73 t_w  4.7 t_f  6.9 r  7.0 A  1640 I_y   5410000 I_z   449000 W_el_y   77300 W_el_z  12300 W_pl_y   88300 W_pl_z  19300}
dict set secI IPE160 {h_w 160 b_f  82 t_w  5 7.t_f  7.0 r  9.0 A  2010 I_y   8690000 I_z   683000 W_el_y  109000 W_el_z  16700 W_pl_y  124000 W_pl_z  26100}
dict set secI IPE180 {h_w 180 b_f  91 t_w  5.3 t_f  8.0 r  9.0 A  2390 I_y  13200000 I_z  1010000 W_el_y  146000 W_el_z  22200 W_pl_y  166000 W_pl_z  34600}
dict set secI IPE200 {h_w 200 b_f 100 t_w  5.6 t_f  8.5 r 12.0 A  2850 I_y  19400000 I_z  1420000 W_el_y  194000 W_el_z  28500 W_pl_y  221000 W_pl_z  44600}
dict set secI IPE220 {h_w 220 b_f 110 t_w  5.9 t_f  9.2 r 12.0 A  3340 I_y  27700000 I_z  2050000 W_el_y  252000 W_el_z  37300 W_pl_y  285000 W_pl_z  58100}
dict set secI IPE240 {h_w 240 b_f 120 t_w  6.2 t_f  9.8 r 15.0 A  3910 I_y  38900000 I_z  2840000 W_el_y  324000 W_el_z  47300 W_pl_y  367000 W_pl_z  73900}
dict set secI IPE270 {h_w 270 b_f 135 t_w  6.6 t_f 10.2 r 15.0 A  4590 I_y  57900000 I_z  4200000 W_el_y  429000 W_el_z  62200 W_pl_y  484000 W_pl_z  97000}
dict set secI IPE300 {h_w 300 b_f 150 t_w  7.1 t_f 10.7 r 15.0 A  5380 I_y  83600000 I_z  6040000 W_el_y  557000 W_el_z  80500 W_pl_y  628000 W_pl_z 125000}
dict set secI IPE330 {h_w 330 b_f 160 t_w  7.5 t_f 11.5 r 18.0 A  6250 I_y 117700000 I_z  7880000 W_el_y  713000 W_el_z  98500 W_pl_y  804000 W_pl_z 154000}
dict set secI IPE360 {h_w 360 b_f 170 t_w  8.0 t_f 12.7 r 18.0 A  7270 I_y 162700000 I_z 10400000 W_el_y  904000 W_el_z 123000 W_pl_y 1019000 W_pl_z 191000}
dict set secI IPE400 {h_w 400 b_f 180 t_w  8.6 t_f 13.5 r 21.0 A  8450 I_y 231300000 I_z 13200000 W_el_y 1160000 W_el_z 146000 W_pl_y 1307000 W_pl_z 229000}
dict set secI IPE450 {h_w 450 b_f 190 t_w  9.4 t_f 14.6 r 21.0 A  9880 I_y 337400000 I_z 16800000 W_el_y 1500000 W_el_z 176000 W_pl_y 1702000 W_pl_z 276000}
dict set secI IPE500 {h_w 500 b_f 200 t_w 10.2 t_f 16.0 r 21.0 A 11600 I_y 482000000 I_z 21400000 W_el_y 1930000 W_el_z 214000 W_pl_y 2194000 W_pl_z 336000}
dict set secI IPE550 {h_w 550 b_f 210 t_w 11.1 t_f 17.2 r 24.0 A 13400 I_y 671200000 I_z 26700000 W_el_y 2440000 W_el_z 254000 W_pl_y 2787000 W_pl_z 401000}
dict set secI IPE600 {h_w 600 b_f 220 t_w 12.0 t_f 19.0 r 24.0 A 15600 I_y 920800000 I_z 33900000 W_el_y 3070000 W_el_z 308000 W_pl_y 3512000 W_pl_z 486000}

dict set secI HEA703 {h_w 5690 b_f 300 t_w 14.5 t_f 27.0}
dict set secI HEB703 {h_w 5700 b_f 300 t_w 17.0 t_f 32.0}

dict set secI IPE751 {h_w 753 b_f 263 t_w 11.5 t_f 17.0 r 17 A 17500 I_y 1599000000 I_z 51660000 W_el_y 4246000 W_el_z 392800 W_pl_y 4865000 W_pl_z 614100}
dict set secI IPE752 {h_w 753 b_f 265 t_w 13.2 t_f 17.0 r 17 A 18800 I_y 1661000000 I_z 52890000 W_el_y 4411000 W_el_z 399200 W_pl_y 5110000 W_pl_z 630800}

dict set secI C180-10 {h_w 160 b_f 166 t_w 14.0 t_f 10.0 r 1 A 5560 I_y 28793000 I_z  7660417 W_el_y 319926 W_el_z  92294 W_pl_y 371800 W_pl_z 145620}
dict set secI C180-12 {h_w 156 b_f 166 t_w 14.0 t_f 12.0 r 1 A 6168 I_y 32588000 I_z  9184264 W_el_y 362089 W_el_z 110654 W_pl_y 419832 W_pl_z 172980}
dict set secI C180-17 {h_w 146 b_f 166 t_w 14.0 t_f 17.0 r 1 A 7688 I_y 41256000 I_z 12994000 W_el_y 458395 W_el_z 156552 W_pl_y 534592 W_pl_z 241380}
dict set secI C180-20 {h_w 140 b_f 166 t_w 14.0 t_f 20.0 r 1 A 8600 I_y 45919000 I_z 15280000 W_el_y 510207 W_el_z 184092 W_pl_y 599800 W_pl_z 282420}
dict set secI C183-23 {h_w 137 b_f 169 t_w 14.0 t_f 23.0 r 1 A 9692 I_y 53096000 I_z 18534000 W_el_y 580286 W_el_z 219338 W_pl_y 687611 W_pl_z 335164}