#===============================================================================
#
#                                                                      RECORDERS
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

proc doRecorders {stories nodes} {
  # drifts are recorded for each story + roof
  
  if {$stories == 2} {
    recorder Drift -file Drifts.osr \
                   -precision 10 \
                   -time \
                   -iNode [lindex $nodes 0] \
                          [lindex $nodes 1] \
                          [lindex $nodes 0] \
                   -jNode [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 2] \
                   -dof 1 \
                   -perpDirn 2
  }
  if {$stories == 3} {
    recorder Drift -file Drifts.osr \
                   -precision 10 \
                   -time \
                   -iNode [lindex $nodes 0] \
                          [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 0] \
                   -jNode [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 3] \
                   -dof 1 \
                   -perpDirn 2
  }
  if {$stories == 4} {
    recorder Drift -file Drifts.osr \
                   -precision 10 \
                   -time \
                   -iNode [lindex $nodes 0] \
                          [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 0] \
                   -jNode [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 4] \
                   -dof 1 \
                   -perpDirn 2
  }
  if {$stories == 5} {
    recorder Drift -file Drifts.osr \
                   -precision 10 \
                   -time \
                   -iNode [lindex $nodes 0] \
                          [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 0] \
                   -jNode [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 5] \
                   -dof 1 \
                   -perpDirn 2
  }
  if {$stories == 6} {
    recorder Drift -file Drifts.osr \
                   -precision 10 \
                   -time \
                   -iNode [lindex $nodes 0] \
                          [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 0] \
                   -jNode [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 6] \
                          [lindex $nodes 6] \
                   -dof 1 \
                   -perpDirn 2
  }
  if {$stories == 7} {
    recorder Drift -file Drifts.osr \
                   -precision 10 \
                   -time \
                   -iNode [lindex $nodes 0] \
                          [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 6] \
                          [lindex $nodes 0] \
                   -jNode [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 6] \
                          [lindex $nodes 7] \
                          [lindex $nodes 7] \
                   -dof 1 \
                   -perpDirn 2
  }
  if {$stories == 8} {
    recorder Drift -file Drifts.osr \
                   -precision 10 \
                   -time \
                   -iNode [lindex $nodes 0] \
                          [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 6] \
                          [lindex $nodes 7] \
                          [lindex $nodes 0] \
                   -jNode [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 6] \
                          [lindex $nodes 7] \
                          [lindex $nodes 8] \
                          [lindex $nodes 8] \
                   -dof 1 \
                   -perpDirn 2
  }
  if {$stories == 12} {
    recorder Drift -file Drifts.osr \
                   -precision 10 \
                   -time \
                   -iNode [lindex $nodes 0] \
                          [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 6] \
                          [lindex $nodes 7] \
                          [lindex $nodes 8] \
                          [lindex $nodes 9] \
                          [lindex $nodes 10] \
                          [lindex $nodes 11] \
                          [lindex $nodes 0] \
                   -jNode [lindex $nodes 1] \
                          [lindex $nodes 2] \
                          [lindex $nodes 3] \
                          [lindex $nodes 4] \
                          [lindex $nodes 5] \
                          [lindex $nodes 6] \
                          [lindex $nodes 7] \
                          [lindex $nodes 8] \
                          [lindex $nodes 9] \
                          [lindex $nodes 10] \
                          [lindex $nodes 11] \
                          [lindex $nodes 12] \
                          [lindex $nodes 8] \
                   -dof 1 \
                   -perpDirn 2
  }

  #recorder Element -file Brace_Forces.osr  -precision 10 -time -ele 100120 300120 1200210 1200230 2100320 2300320 3200410 3200430 axialForce
  #recorder Element -file Brace_Defs.osr    -precision 10 -time -ele 100120 300120 1200210 1200230 2100320 2300320 3200410 3200430 deformations
  #recorder Node    -file Reactions.osr     -precision 10 -time -node 18 28 38 -dof 1 reaction
  #recorder Element -file Column_Forces.osr -precision 10 -time -ele 180112 280122 380132 force
}