awk '
  NR==1 { u=$2+$4; t=$2+$3+$4+$5 }
  NR==2 { print int(($2+$4-u)/($2+$3+$4+$5-t)*100) }
' <(grep "^cpu " /proc/stat) <(sleep 0.3; grep "^cpu " /proc/stat)
