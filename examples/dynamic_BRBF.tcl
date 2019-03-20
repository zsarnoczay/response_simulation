#===============================================================================                                     
#
#                                                        author: Adam Zsarnóczay
#                                                        created:  2015. 05. 13.
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

wipe all

# load the core methods
source ../core/setAnalysis.tcl
source ../core/setRecorders.tcl
source ../core/Basics.tcl

# load the model info
source ../BRBF/Zsarnoczay_Vigh_2017/8AHHD.tcl

# load the ground motion and set its characteristics
set eqPath ../EQ/FEMA-P695-FF/6.rec

set dt 0.01
set npts 4531
set npts [expr $npts + 2.0/$dt]
set F 1.0

# specify the story height and the nodes for drift monitoring
set h {4.0 4.0 4.0 4.0 4.0 4.0 4.0 4.0}
set driftNodes {0 100 200 300 400 500 600 700 800}

# build the model
set pushover 0
source ../core/ModelBuilder.tcl

#load the ground motion record
set AccelSeries "Series -dt $dt -filePath $eqPath -factor [expr $F*$factorG]"
pattern UniformExcitation 703140799 1 -accel $AccelSeries

#create the recorders
doRecorders $stories $driftNodes

# set the limits for convergence tolerance and timestep size
set minDiv 8
set tol -8

#run the analysis
set ok [doDynamicAnalysis $npts $dt $stories $h $driftNodes $modelType \
                          [expr pow(10.,$tol)] $minDiv]

if {$ok == 0} {
  puts "analysis COMPLETED"
} elseif {$ok == 1} {
  puts "analysis FAILED - drift limit exceeded"
} else {
  puts "analysis FAILED - convergence problem"
}

wipeAnalysis
wipe


