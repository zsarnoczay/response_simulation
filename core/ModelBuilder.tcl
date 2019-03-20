#===============================================================================
#
#                                            GENERAL INPUT FILE FOR STEEL FRAMES
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

# set a correction factor for gravity load
set factorG 1.0

# modelTypes:
# EXT - external, do not use ModelBuilder
# BRBF - Buckling Restrained Braced Frame - pinned BRBs and pinned beams
# MRF - steel moment frame

if {$modelType != "EXT"} {

  # initialize the model and start monitoring the time
  wipe
  set start [clock milliseconds]

  model BasicBuilder -ndm 2 -ndf 3

  # analysis options
  #set pushover 0
  #set pushShape 1
  set pDelta 1
  set diaphragms 0
  set display 0

  # base height [m]
  set H0 0.0

  # base masses / for coding convenience since the base is supported anyway
  set M0 0.0
  set M10 0.0
  set M20 0.0
  set M30 0.0

  #offset is only used to visualize the joint nodes - use 0.0 for the actual calculation
  #set offset 0.5
  set offset 0.0

  #=============================================================================
  #
  #                                                          MATERIAL PROPERTIES
  #
  #=============================================================================
  #_____________________________________________________________________________
  #                                                         ultra-rigid material
  set matUR 100
  URmat $matUR
  #_____________________________________________________________________________
  #                                                braced frame column materials
  #columns are assumed elastic with plastic hinges at the end
  set Fyd_col [expr 235*$MPa]
  set Fy_col [expr 275*$MPa];
  set E_col [expr 210*$GPa];

  #_____________________________________________________________________________
  #                                                     plastic hinge materials
  #column hinges are installed for all frames
  set L_hinge 0.2
  set n [expr $X1 / (2 * $L_hinge) - 1.0]
  for {set i 0} {$i<$stories} {incr i 1} {
    set L_col [expr [subst "\$H[expr $i+1]"] - [subst "\$H[expr $i]"]]
    IKmat [expr 111 + $i*10] $Fy_col $n $L_col [dict get $secI [subst "\$E[expr 111 + $i*10]S"]] $mm \
          [subst "\$E[expr 111 + $i*10]M"] 0.0 $colDir $Fyd_col

    IKmat [expr 112 + $i*10] $Fy_col $n $L_col [dict get $secI [subst "\$E[expr 112 + $i*10]S"]] $mm \
          [subst "\$E[expr 112 + $i*10]M"] 0.0 $colDir $Fyd_col
  }

  #beam hinges are only installed for MRF
  if {$modelType == "MRF"} {
    for {set i 0} {$i<$stories} {incr i 1} {
      set L_beam $X1
      IKmat [expr 211 + $i*10] $Fy_col $n $L_beam [dict get $secI [subst "\$E[expr 211 + $i*10]S"]] $mm \
            [subst "\$E[expr 211 + $i*10]M"] [subst "\$E[expr 211 + $i*10]R"] 0 $Fyd_col
    }
  }

  #_____________________________________________________________________________
  #                                                                BRB materials
  if {$modelType == "BRBF"} {
    for {set i 0} {$i<$stories} {incr i 1} {
      BRBmat [expr 310 + $i*10] [subst "\$E[expr 311 + $i*10]A"] [subst "\$SMF[expr $i + 1]"] \
          [subst "\$DMF[expr $i + 1]"] [expr 235*$MPa] 1.13 $pushover
    }
  }
  #=============================================================================
  #
  #                                                                     SECTIONS
  #
  #=============================================================================

  #assign 10 m2 to the ultra rigid sections
  set secUR 10.0

  #=============================================================================
  #
  #                                                                     GEOMETRY
  #
  #=============================================================================
  #_____________________________________________________________________________
  #                                                                                             nodes

  #leaning columns
  if {$M100 > 0} {
    for {set i 0} {$i<=$stories} {incr i 1} {
      set colMass [expr [subst "\$M[expr $i*100]"]/2.0]
      node [expr  0 + $i*100] [expr -$X1/2.0] [subst "\$H[expr $i]"] \
           -mass $colMass $colMass 0
      node [expr 90 + $i*100] [expr ($bays + 0.5) * $X1] [subst "\$H[expr $i]"] \
           -mass $colMass $colMass 0
    }
  }
  #braced frame columns
  for {set i 0} {$i <= $stories} {incr i 1} {
    for {set j 0} {$j <= $bays} {incr j 1} {
      if {$j == 0 || $j == $bays} {
        #perimeter columns
        set colMass [expr [subst "\$M[expr $i*100 + 10]"] + [subst "\$M[expr $i*100 + 30]"] / 2.0]
        node [expr 10 + $j * 10 + $i*100] [expr $j * $X1] [subst "\$H[expr $i]"] \
             -mass $colMass $colMass 0
      } else {
        #inner columns
        set colMass [expr [subst "\$M[expr $i*100 + 20]"] + [subst "\$M[expr $i*100 + 30]"]]
        node [expr 10 + $j * 10 + $i*100] [expr $j * $X1] [subst "\$H[expr $i]"] \
             -mass $colMass $colMass 0
      }
    }
  }

  #nodes for plastic hinges at column ends
  for {set i 0} {$i <= $stories} {incr i 1} {
    for {set j 0} {$j <= $bays} {incr j 1} {
      if {$i < $stories} {
        node [expr 18 + $j * 10 + $i*100] [expr $j * $X1] [expr [subst "\$H[expr $i]"] + $offset]
      }
      if {$i > 0} {
        node [expr 12 + $j * 10 + $i*100] [expr $j * $X1] [expr [subst "\$H[expr $i]"] - $offset]
      }
    }
  }

  #nodes for plastic hinges at beam ends
  if {$modelType == "MRF"} {
    for {set i 1} {$i <= $stories} {incr i 1} {
      for {set j 0} {$j <= $bays} {incr j 1} {
        if {$j > 0} {
          node [expr 14 + $j * 10 + $i*100] [expr $j * $X1 - 2 * $offset] [subst "\$H[expr $i]"]
        }
        if {$j < $bays} {
          node [expr 16 + $j * 10 + $i*100] [expr $j * $X1 + 2 * $offset] [subst "\$H[expr $i]"]
        }
      }
    }
  }

  #_____________________________________________________________________________
  #                                                           degrees of freedom

  #leaning columns
  if {$M100 > 0} {
    fix  0 1 1 1
    fix 90 1 1 1
    for {set i 1} {$i <= $stories} {incr i 1} {
      fix [expr  0 + $i*100] 0 0 1
      fix [expr 90 + $i*100] 0 0 1
    }
  }

  #braced column bases
  for {set j 0} {$j <= $bays} {incr j 1} {
    fix [expr 10 + $j * 10] 1 1 $column_base
  }

  #=============================================================================
  #
  #                                                                     ELEMENTS
  #
  #=============================================================================
  #_____________________________________________________________________________
  #                                                              transformations
  set ColumnTR 32
  if {$pDelta == 0} {
    geomTransf Linear $ColumnTR
    set trussType truss
  }
  if {$pDelta == 1} {
    geomTransf Corotational $ColumnTR
    set trussType corotTruss
  }
  #_____________________________________________________________________________
  #                                                           integration points
  set gaussCol 5
  #_____________________________________________________________________________
  #                     leaning columns - infinitely rigid trusses on both sides
  if {$M100 > 0} {
    for {set i 0} {$i<$stories} {incr i 1} {
      element $trussType [expr ($i * 100) * 10000 + ($i + 1) * 100] \
              [expr $i*100] [expr ($i + 1) * 100] $secUR $matUR
      element $trussType [expr ($i * 100 + 90) * 10000 + ($i + 1) * 100 + 90] \
              [expr $i*100 + 90] [expr ($i + 1) * 100 + 90] $secUR $matUR
    }
  }
  #_____________________________________________________________________________
  #                                                                frame columns
  for {set i 0} {$i<$stories} {incr i 1} {
    #perimeter columns
    set columnSection [dict get $secI [subst "\$E[expr 111 + $i*10]S"]]
    set column_A [expr [dict get $columnSection A]*$mm2]
    if {$colDir == 0} {
      set column_I [expr (($n+1)/$n)*[dict get $columnSection I_y]*$mm4] }
    if {$colDir == 90} {
      set column_I [expr (($n+1)/$n)*[dict get $columnSection I_z]*$mm4] }
    element elasticBeamColumn [expr (18 + $i * 100) * 10000 + (112 + $i * 100)] \
            [expr 18 + $i * 100] [expr 112 + $i * 100] \
            $column_A \
            $E_col \
            $column_I \
            $ColumnTR
    element elasticBeamColumn \
            [expr (18 + $i * 100 + $bays * 10) * 10000 + (112 + $i * 100  + $bays * 10)] \
            [expr 18 + $i * 100 + $bays * 10] [expr 112 + $i * 100 + $bays * 10] \
            $column_A \
            $E_col \
            $column_I \
            $ColumnTR
    #inner columns
    set columnSection [dict get $secI [subst "\$E[expr 112 + $i*10]S"]]
    set column_A [expr [dict get $columnSection A]*$mm2]
    if {$colDir == 0} {
      set column_I [expr (($n+1)/$n)*[dict get $columnSection I_y]*$mm4] }
    if {$colDir == 90} {
      set column_I [expr (($n+1)/$n)*[dict get $columnSection I_z]*$mm4] }
    for {set j 1} {$j<$bays} {incr j 1} {
      element elasticBeamColumn \
              [expr (18 + $i * 100 + $j * 10) * 10000 + (112 + $i * 100  + $j * 10)] \
              [expr 18 + $i * 100 + $j * 10] [expr 112 + $i * 100 + $j * 10] \
              $column_A \
              $E_col \
              $column_I \
              $ColumnTR
    }
  }

  #_____________________________________________________________________________
  #                                                                  frame beams

  #beams between the leaning column and the braced frame
  if {$M100 > 0} {
    for {set i 1} {$i<=$stories} {incr i 1} {
      element $trussType [expr ($i * 100) * 10000 + 10 + $i * 100] \
              [expr $i*100] [expr 10 + $i * 100] $secUR $matUR
      element $trussType [expr (($bays + 1) * 10 + $i * 100) * 10000 + 90 + $i * 100] \
              [expr ($bays + 1) * 10 + $i * 100] [expr 90 + $i * 100] $secUR $matUR
    }
  }

  #beams with moment resisting connections in the braced frame
  if {$modelType == "MRF"} {
    for {set i 1} {$i <= $stories} {incr i 1} {
      set beamSection [dict get $secI [subst "\$E[expr 201 + $i*10]S"]]
      for {set j 0} {$j < $bays} {incr j 1} {
        element elasticBeamColumn \
                [expr (16 + $i * 100 + $j * 10) * 10000 + (24 + $i * 100 + $j * 10)]\
                [expr 16 + $i * 100 + $j * 10] [expr 24 + $i * 100 + $j * 10] \
                [expr [dict get $beamSection A]*$mm2] \
                $E_col \
                [expr (($n+1)/$n)*[dict get $beamSection I_y]*$mm4] \
                $ColumnTR
      }
    }
  }

  #beams with pinned connections and ultra rigid material to represent slab stiffness
  if {$modelType == "BRBF"} {
    for {set i 1} {$i <= $stories} {incr i 1} {
      for {set j 0} {$j < $bays} {incr j 1} {
        element $trussType \
                [expr (10 + $i * 100 + $j * 10) * 10000 + (20 + $i * 100 + $j * 10)]\
                [expr 10 + $i * 100 + $j * 10] [expr 20 + $i * 100 + $j * 10] \
                $secUR $matUR
      }
    }
  }

  #_____________________________________________________________________________
  #                                                                         BRBs
  if {$modelType == "BRBF"} {
    #2-bay chevron configuration
    for {set i 0} {$i < $stories} {incr i 1} {
      for {set j 0} {$j < $bays} {incr j 1} {
        if {[expr fmod($i,2)] == 0} {
          if {[expr fmod($j,2)] == 0} {
            element $trussType [expr (10 + $i * 100 + $j * 10) * 10000 + (120 + $i * 100 + $j * 10)] \
                    [expr 10 + $i * 100 + $j * 10] [expr 120 + $i * 100 + $j * 10] \
                    [subst "\$E[expr 311 + $i*10]A"] [expr 310 + $i * 10]
          } else {
            element $trussType [expr (20 + $i * 100 + $j * 10) * 10000 + (110 + $i * 100 + $j * 10)] \
                    [expr 20 + $i * 100 + $j * 10] [expr 110 + $i * 100 + $j * 10] \
                    [subst "\$E[expr 311 + $i*10]A"] [expr 310 + $i * 10]
          }
        } else {
          if {[expr fmod($j,2)] == 0} {
            element $trussType [expr (20 + $i * 100 + $j * 10) * 10000 + (110 + $i * 100 + $j * 10)] \
                    [expr 20 + $i * 100 + $j * 10] [expr 110 + $i * 100 + $j * 10] \
                    [subst "\$E[expr 311 + $i*10]A"] [expr 310 + $i * 10]
          } else {
            element $trussType [expr (10 + $i * 100 + $j * 10) * 10000 + (120 + $i * 100 + $j * 10)] \
                    [expr 10 + $i * 100 + $j * 10] [expr 120 + $i * 100 + $j * 10] \
                    [subst "\$E[expr 311 + $i*10]A"] [expr 310 + $i * 10]
          }
        }
      }
    }
  }

  #_____________________________________________________________________________
  #                                                               plastic hinges
  #in frame columns
  for {set i 0} {$i < $stories} {incr i 1} {
    #perimeter columns
    if {[subst "\$E[expr 111 + $i*10]M"] > 0} {
      element zeroLength [expr (10 + $i * 100) * 10000 + (18 + $i * 100)] \
              [expr 10 + $i * 100] [expr 18 + $i * 100] -mat [expr 111 + $i * 10] -dir 6
      equalDOF [expr 10 + $i * 100] [expr 18 + $i * 100] 1 2
      element zeroLength [expr (110 + $i * 100) * 10000 + (112 + $i * 100)] \
              [expr 110 + $i * 100] [expr 112 + $i * 100] -mat [expr 111 + $i * 10] -dir 6
      equalDOF [expr 110 + $i * 100] [expr 112 + $i * 100] 1 2

      element zeroLength [expr (10 + $i * 100 + $bays * 10) * 10000 + (18 + $i * 100 + $bays * 10)] \
              [expr 10 + $i * 100 + $bays * 10] [expr 18 + $i * 100 + $bays * 10] \
              -mat [expr 111 + $i * 10] -dir 6
      equalDOF [expr 10 + $i * 100 + $bays * 10] [expr 18 + $i * 100 + $bays * 10] 1 2
      element zeroLength [expr (110 + $i * 100 + $bays * 10) * 10000 + (112 + $i * 100 + $bays * 10)] \
              [expr 110 + $i * 100 + $bays * 10] [expr 112 + $i * 100 + $bays * 10] \
              -mat [expr 111 + $i * 10] -dir 6
      equalDOF [expr 110 + $i * 100 + $bays * 10] [expr 112 + $i * 100 + $bays * 10] 1 2
    } else {
      equalDOF [expr 10 + $i * 100] [expr 18 + $i * 100] 1 2
      equalDOF [expr 110 + $i * 100] [expr 112 + $i * 100] 1 2
      equalDOF [expr 10 + $i * 100 + $bays * 10] [expr 18 + $i * 100 + $bays * 10] 1 2
      equalDOF [expr 110 + $i * 100 + $bays * 10] [expr 112 + $i * 100 + $bays * 10] 1 2

      if {$i > 0} {
        fix [expr 10 + $i * 100]               0 0 1   
        fix [expr 110 + $i * 100]              0 0 1 
        fix [expr 10 + $i * 100 + $bays * 10]  0 0 1 
        fix [expr 110 + $i * 100 + $bays * 10] 0 0 1 
      }
    }

    #inner columns
    for {set j 1} {$j < $bays} {incr j 1} {
      if {[subst "\$E[expr 112 + $i*10]M"] > 0} {
        element zeroLength [expr (10 + $i * 100 + $j * 10) * 10000 + (18 + $i * 100 + $j * 10)] \
                [expr 10 + $i * 100 + $j * 10] [expr 18 + $i * 100 + $j * 10] \
                -mat [expr 112 + $i * 10] -dir 6
        equalDOF [expr 10 + $i * 100 + $j * 10] [expr 18 + $i * 100 + $j * 10] 1 2
        element zeroLength [expr (110 + $i * 100 + $j * 10) * 10000 + (112 + $i * 100 + $j * 10)] \
                [expr 110 + $i * 100 + $j * 10] [expr 112 + $i * 100 + $j * 10] \
                -mat [expr 112 + $i * 10] -dir 6
        equalDOF [expr 110 + $i * 100 + $j * 10] [expr 112 + $i * 100 + $j * 10] 1 2
      } else {
        equalDOF [expr 10 + $i * 100 + $j * 10] [expr 18 + $i * 100 + $j * 10] 1 2
        equalDOF [expr 110 + $i * 100 + $j * 10] [expr 112 + $i * 100 + $j * 10] 1 2

        if {$i > 0} {
          fix [expr 10 + $i * 100 + $j * 10]   0 0 1   
          fix [expr 110 + $i * 100 + $j * 10]  0 0 1 
        }
      }
    }
  }

  #in-frame beams
  if {$modelType == "MRF"} {
    for {set i 1} {$i <= $stories} {incr i 1} {
      for {set j 0} {$j <= $bays} {incr j 1} {
        if {$j < $bays} {
          element zeroLength [expr (10 + $i * 100 + $j * 10) * 10000 + (16 + $i * 100 + $j * 10)] \
                  [expr 10 + $i * 100 + $j * 10] [expr 16 + $i * 100 + $j * 10] \
                  -mat [expr 201 + $i * 10] -dir 6
          equalDOF [expr 10 + $i * 100 + $j * 10] [expr 16 + $i * 100 + $j * 10] 1 2
        }
        if {$j > 0} {
          element zeroLength [expr (10 + $i * 100 + $j * 10) * 10000 + (14 + $i * 100 + $j * 10)] \
                  [expr 10 + $i * 100 + $j * 10] [expr 14 + $i * 100 + $j * 10] \
                  -mat [expr 201 + $i * 10] -dir 6
          equalDOF [expr 10 + $i * 100 + $j * 10] [expr 14 + $i * 100 + $j * 10] 1 2
        }
      }
    }
  }

  #=============================================================================
  #
  #                                                                      DISPLAY
  #
  #=============================================================================
  if {$display == 1} {
    recorder display "Model" 10 10 900 900 -wipe
    prp 0 0 50
    vup 0 1 0
    vpn 0 0 1
    display 1 -1 5
  }
  #=============================================================================
  #
  #                                                          EIGENVALUE ANALYSIS
  #
  #=============================================================================
  set modeCount 2;
  set lambdaN [eigen $modeCount];        # eigenvalue analysis for modeCount modes
  set lambdaI [lindex $lambdaN [expr 0]];     # eigenvalue mode i = 1
  set lambdaJ [lindex $lambdaN [expr $modeCount-1]];     # eigenvalue mode i = 1
  set w1 [expr pow($lambdaI,0.5)];            # w1 (1st mode circular frequency)
  set w2 [expr pow($lambdaJ,0.5)];            # w1 (1st mode circular frequency)
  set T1 [expr 2.0*$pi/$w1];                  # 1st mode period of the structure
  set T2 [expr 2.0*$pi/$w2];                  # 1st mode period of the structure
  puts "T1= $T1 s";                           # display the first mode period in the command window
  puts "T2= $T2 s";                           # display the first mode period in the command window

  #=============================================================================
  #
  #                                                                      DAMPING
  #
  #=============================================================================
  # RAYLEIGH damping parameters
  set xDamp 0.02
  #the lower frequency is 5Hz as per the recommendations of FEMA355
  set w2 [expr 2.0*$pi/0.2]
  #for the masses
  set a0 [expr $xDamp*2.0*$w1*$w2/($w1+$w2)]
  #other elastic elements with no hinges
  set a1 [expr ($xDamp*2.0/($w1 + $w2))]
  #for elastic elements with plastic hinges according to Zareian & Medina 2010
  set a1_mod [expr ($xDamp*2.0/($w1 + $w2))*(1.0+$n)/$n]

  #apply mass proportional damping for the nodes with lumped masses
  for {set i 0} {$i < $stories} {incr i 1} {
    for {set j 0} {$j <= $bays+1} {incr j 1} {
      region [expr 100 + $i*100 + $j*10] -node [expr 100 + $i*100 + $j*10] -rayleigh $a0 0.0 0.0 0.0
    }
    region [expr 190 + $i*100] -node [expr 190 + $i*100] -rayleigh $a0 0.0 0.0 0.0
  }
  #apply tangent stiffness proportional damping for elastic elements
  if {$modelType == "MRF"} {
    for {set i 1} {$i <= $stories} {incr i 1} {
      for {set j 0} {$j < $bays} {incr j 1} {
        region [expr (16 + $i * 100 + $j * 10) * 10000 + (24 + $i * 100 + $j * 10)] \
               -ele [expr (16 + $i * 100 + $j * 10) * 10000 + (24 + $i * 100 + $j * 10)] \
               -rayleigh 0.0 0.0 $a1_mod 0.0
      }
    }
  }
  for {set i 0} {$i<$stories} {incr i 1} {
    #perimeter columns
    region [expr (18 + $i * 100) * 10000 + (112 + $i * 100)] \
           -ele [expr (18 + $i * 100) * 10000 + (112 + $i * 100)] \
           -rayleigh 0.0 0.0 $a1_mod 0.0
    region [expr (18 + $i * 100 + $bays * 10) * 10000 + (112 + $i * 100  + $bays * 10)] \
           -ele [expr (18 + $i * 100 + $bays * 10) * 10000 + (112 + $i * 100  + $bays * 10)] \
           -rayleigh 0.0 0.0 $a1_mod 0.0
    #inner columns
    for {set j 1} {$j<$bays} {incr j 1} {
      region [expr (18 + $i * 100 + $j * 10) * 10000 + (112 + $i * 100  + $j * 10)] \
           -ele [expr (18 + $i * 100 + $j * 10) * 10000 + (112 + $i * 100  + $j * 10)] \
           -rayleigh 0.0 0.0 $a1_mod 0.0
    }
  }

  #=============================================================================
  #
  #                                                                 STATIC LOADS
  #
  #=============================================================================
  #_____________________________________________________________________________
  #                                                                gravity loads
  pattern Plain 1 Linear {
    for {set i 1} {$i <= $stories} {incr i 1} {
      #leaning columns
      if {$M100 > 0} {
        load [expr      $i * 100] 0.0 [expr -[subst "\$M[expr 100*$i]"] /2.0 * $g * 1.0] 0.0
        load [expr 90 + $i * 100] 0.0 [expr -[subst "\$M[expr 100*$i]"] /2.0 * $g * 1.0] 0.0
      }
      #perimeter columns
      load [expr 10 + $i * 100] 0.0 [expr -[subst "\$M[expr 10 + 100*$i]"] * $g * 1.0] 0.0
      load [expr 10 + $i * 100 + $bays * 10] 0.0 [expr -[subst "\$M[expr 10 + 100*$i]"] * $g * 1.0] 0.0
      #inner columns
      for {set j 1} {$j < $bays} {incr j 1} {
        load [expr 10 + $i * 100 + $j * 10] 0.0 [expr -[subst "\$M[expr 20 + 100*$i]"] * $g * 1.0] 0.0
      }
    }

    #distributed load on beams
    if {$modelType == "MRF"} {
      for {set i 1} {$i <= $stories} {incr i 1} {
        for {set j 0} {$j < $bays} {incr j 1} {
          eleLoad -ele [expr (16 + $i * 100 + $j * 10) * 10000 + (24 + $i * 100 + $j * 10)] \
                  -type -beamUniform [expr -[subst "\$M[expr 30 + 100*$i]"] * $g / $X1 * 1.0]
        }
      }
    }         
  }

  #_____________________________________________________________________________
  #                                                             gravity analysis
  doGravityAnalysis;
  loadConst  -time 0.0

  if {$pushover == 1} {
    #===========================================================================
    #
    #                                                             PUSHOVER LOADS
    #
    #===========================================================================

    # depending on the settings use either the modal or the uniform shape
    # simplify things a bit and only put load on the leaning columns
    if {$pushShape == 0} {
      #set totalMass [expr 2*(0.016*$N100M+0.036*$N200M+0.054*$N300M+0.072*$N400M)]
      set totalMass [expr 2*($M100+$M200)]
      set height $H2
      if {$stories>2} {
        set height $H3
        set totalMass [expr $totalMass + $M300*2]
        if {$stories > 3} {
          set height $H4
          set totalMass [expr $totalMass + $M400*2]
          if {$stories > 4} {
            set height $H5
            set totalMass [expr $totalMass + $M500*2]
            if {$stories > 5} {
              set height $H6
              set totalMass [expr $totalMass + $M600*2]
            }
          }
        }
      }
      pattern Plain 2 Linear {
        load 100 [expr $M100 / $totalMass] 0 0
        load 190 [expr $M100 / $totalMass] 0 0
        load 200 [expr $M200 / $totalMass] 0 0
        load 290 [expr $M200 / $totalMass] 0 0
        if {$stories > 2} {
          load 300 [expr $M300 / $totalMass] 0 0
          load 390 [expr $M300 / $totalMass] 0 0
        }
        if {$stories > 3} {
          load 400 [expr $M400 / $totalMass] 0 0
          load 490 [expr $M400 / $totalMass] 0 0
        }
        if {$stories > 4} {
          load 500 [expr $M500 / $totalMass] 0 0
          load 590 [expr $M500 / $totalMass] 0 0
        }
        if {$stories > 5} {
          load 600 [expr $M600 / $totalMass] 0 0
          load 690 [expr $M600 / $totalMass] 0 0
        }
      }
    }
    if {$pushShape > 0} {
      #first get the eigenvector for the specified mode
      set count 0
      set total 0
      for {set i 1} {$i <= $stories} {incr i} {
        if {$M100 > 0} { set nodeList($count) [expr 100*$i];}
        if {$M100 == 0} { set nodeList($count) [expr 100*$i+10];}
        set eigenList($count) [nodeEigenvector $nodeList($count) $pushShape 1]
        set total [expr $total + $eigenList($count)]
        incr count
        if {$M100 > 0} { set nodeList($count) [expr 100*$i+90];}
        if {$M100 == 0} { set nodeList($count) [expr 100*$i+($bays+1)*10];}
        set eigenList($count) [nodeEigenvector $nodeList($count) $pushShape 1]
        set total [expr $total + $eigenList($count)]
        incr count
      }
      pattern Plain 2 Linear {
        for {set i 0} {$i < $count} {incr i} {
          load $nodeList($i) [expr $eigenList($i)/$total] 0 0
        }
      }
    }
  }
}