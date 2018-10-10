import sys
import os
import subprocess

ExecutableName = sys . argv [ 1 ]
InputFolder = sys . argv [ 2 ]
OutputFolder = sys . argv [ 3 ]

print ( sys . argv )

for filename in os.listdir(InputFolder):
  print ( filename )
  filename2, file_extension = os.path.splitext(filename)
  subproc_array = [ './' + ExecutableName , '<' , InputFolder + '/' + filename , '>' , OutputFolder + '/' + filename2 + '-my' + file_extension ]
  proc_string = ''
  for Item in subproc_array :
    proc_string = proc_string + Item + ' '
  #subprocess.call( subproc_array )
  os.system(proc_string)
