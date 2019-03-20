#===============================================================================
#
#                                                METHODS FOR RESPONSE SIMULATION
#
#                                                        author: Adam Zsarnóczay
#                                                        created:  2015. 10. 20.
#
# Copyright (c) 2015 Adam Zsarnóczay
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

#_______________________________________________________________________________
#                                                        static gravity analysis
proc doGravityAnalysis {} {
  puts "Running Gravity Analysis..."

  constraints Transformation
  numberer RCM
  system UmfPack
  test NormDispIncr 1.0e-10 20
  algorithm Newton
  integrator LoadControl   0.1
  analysis Static

  return [analyze 10]
}

#_______________________________________________________________________________
#                                                              pushover analysis
proc doPushoverAnalysis {IDctrlNode IDctrlDOF DispIncr Steps} {
  puts "Running Pushover Analysis..."

  set Astart [clock milliseconds]

  constraints Transformation
  numberer RCM
  system BandGeneral
  test NormDispIncr 1.e-6 100
  algorithm NewtonLineSearch -maxIter 100
  analysis Static

  integrator DisplacementControl $IDctrlNode $IDctrlDOF $DispIncr

  set ok 0
  set ok [analyze $Steps]

  set Afinish [clock milliseconds]
  set ArunTime [expr ($Afinish-$Astart)/1000.0]
  puts "analysis time: $ArunTime seconds"

  return $ok
}

#_______________________________________________________________________________
#                                              dynamic response history analysis
proc doDynamicAnalysis {npts dt stories h nodes modelType tol subSteps} {

  puts "Running Dynamic Analysis..."

  set Astart [clock milliseconds]

  set maxDiv 1024
  set minDiv $subSteps

  set driftLimit 0.25

  constraints Transformation
  numberer RCM
  system UmfPack
  #test NormDispIncr 1.e-8 30
  test NormDispIncr $tol 30
  algorithm NewtonLineSearch
  integrator Newmark 0.5 0.25
  analysis Transient

  set step 0
  set ok 0
  set break 0
  set maxDrift 0

  while {$step<=$npts && $ok==0 && $break==0} {
    set step [expr $step+1]
    set ok 2
    set div $minDiv
    set len $maxDiv
    while {$div <= $maxDiv && $len > 0 && $break == 0} {
      set stepSize [expr $dt/$div]
      set ok [analyze 1 $stepSize]      
      if {$ok==0} {
        set len [expr $len-$maxDiv/$div]
        #check the drift
        set level 1
        while {$level <= $stories} {
          set topDisp [nodeDisp [lindex $nodes [expr $level  ]] 1]
          set botDisp [nodeDisp [lindex $nodes [expr $level-1]] 1]
          set deltaDisp [expr abs($topDisp-$botDisp)]
          set drift [expr $deltaDisp/[lindex $h [expr $level-1]]]
          set level [expr $level + 1]
          if {$drift >= $driftLimit} {set break 1}
        }  
      } else {
        set div [expr $div*2]
        puts "number of substeps increased to $div"
      }
    }
  }
  if {$break == 1} {
    set ok 1
  }

  set Afinish [clock milliseconds]
  set ArunTime [expr ($Afinish-$Astart)/1000.0]
  puts "analysis time: $ArunTime seconds"

  return $ok
}