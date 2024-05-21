#!/bin/bash
rm -rf etot.dat
m=0
mmax=4
while [ "$m" -le "$mmax" ]
do
alen=`echo "3.80197566+0.03879567*$m" | bc -l`

n=0
nmax=4
while [ "$n" -le "$nmax" ]
do

cbya=`echo "3.80197566+0.03879567*$n" | bc -l`

cat > F-SiC5.fdf<<EOF
-----------------------------------------------------------------------------
# Created by GDIS version 0.90.0
#

SystemLabel      F-SiC5

NumberOfAtoms    10

NumberOfSpecies  3
%block ChemicalSpeciesLabel
    1   14  Si
    2    6  C
    3    9  F
%endblock ChemicalSpeciesLabel

LatticeConstant 1.0 Ang
%block LatticeParameters
 $alen    $cbya   20.637347  89.9974     89.9982     90.0010
%endblock LatticeParameters

AtomicCoordinatesFormat Fractional
%block AtomicCoordinatesAndAtomicSpecies
    0.50015458   -0.00001970    0.21460894   1       1  Si
    0.00015576    0.49998631    0.21461562   2       2  C
    0.33025889    0.62252025    0.25890331   2       3  C
    0.87761405    0.83011314    0.17031913   2       4  C
    0.12270384    0.16989292    0.17031806   2       5  C
    0.67001874    0.37742042    0.25890205   2       6  C
    0.23821406    0.70096621    0.32170709   3       7  F
    0.76203188    0.29892617    0.32170572   3       8  F
    0.79919987    0.73809131    0.10751274   3       9  F
    0.20115330    0.26194217    0.10751184   3      10  F
%endblock AtomicCoordinatesAndAtomicSpecies

%block kgrid_Monkhorst_Pack
   20  0   0   0.0
   0   20   0   0.0
   0   0    1   0.0
%endblock kgrid_Monkhorst_Pack


PAO.BasisSize     DZP

------------------------------------------------------------------
----------------------------------------------------------------------
xc.functional         GGA           # Exchange-correlation functional
xc.authors            PBE           # Exchange-correlation version
------------------------------------------------------------------------------------
#SpinPolarized         true          # Logical parameters are: yes or no

MeshCutoff           350. Ry        # Mesh cutoff. real space mesh 

# SCF options
DM.MixingWeight   0.02         # New DM amount for next SCF cycle
DM.Tolerance          1.d-5        # Tolerance in maximum difference                                   
DM.UseSaveDM          true          # to use continuation files
DM.NumberPulay         3

-----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
MD.TypeOfRun           cg           # Type of dynamics:
MD.NumCGsteps          1000         # Number of CG steps for 
MaxSCFIterations       300                                   #   coordinate optimization
MD.MaxCGDispl          0.1 Ang      # Maximum atomic displacement 
MD.MaxForceTol         0.01 eV/Ang  # Tolerance in the maximum 
MD.VariableCell     F
MD.ConstantVolume  	F
MD.UseSaveCG    	F                                   #   atomic force (Ry/Bohr)
SaveRho        .true.
WriteCoorXmol   .true.

EOF

mpirun siesta<  F-SiC5.fdf >  F-SiC5.out
te=`grep Total =  F-SiC5.out | tail -1 | awk '{print $4}'`
echo "$alen  $cbya  $te" >> etot.dat
mv  F-SiC5.fdf  F-SiC5$m.$n.fdf
mv  F-SiC5.out  F-SiC5$m.$n.out
#rm -rf pwscf.*
let n=$n+1
done

let m=$m+1
done
rm -rf *.out *.fdf
# Read data file
datafile="etot.dat"

# Read value of 13th row for each column
col1=$(awk 'FNR == 13 {print $1}' $datafile)
col2=$(awk 'FNR == 13 {print $2}' $datafile)
col3=$(awk 'FNR == 13 {print $3}' $datafile)

# Perform calculations and write to output file
outputfile="data.out"
awk -v c1="$col1" -v c2="$col2" -v c3="$col3" '{print ($1-c1)/c1, ($2-c2)/c2, $3-c3}' $datafile > $outputfile

echo "Output written to $outputfile"
python3 mech.py
