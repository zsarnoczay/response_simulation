#===============================================================================                                     
#
#                                                        author: Adam Zsarnóczay
#                                                        created:  2015. 12. 02.
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

# specify the story height and the nodes for drift monitoring
set h {4.0 4.0 4.0 4.0 4.0 4.0 4.0 4.0}
set driftNodes {0 100 200 300 400 500 600 700 800}

# build the model
set pushover 1
set pushShape 0
source ../core/ModelBuilder.tcl

#create the recorders
doRecorders $stories $driftNodes

set height [subst "\$H[expr $stories]"]
set IDctrlNode [expr 100*$stories+10]
set IDctrlDOF 1
set DispMax [expr $height*0.01]
set DispIncr [expr $stories*0.000025]
set Steps [expr int($DispMax / $DispIncr)]

set ok [doPushoverAnalysis $IDctrlNode $IDctrlDOF $DispIncr $Steps]

if {$ok == 0} {
  puts "analysis COMPLETED"
} else {
  puts "analysis FAILED"
}

wipeAnalysis
wipe
