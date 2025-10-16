-- Info package
Select logdpid, oltpsource
from
`sap-iac-test.bq_toolkit_bw7.rsldpio`
where objvers = 'A'
and oltpsource = '2LIS_12_VCHDR';

-- DTPs
Select dtp,
src,
srctp,
tgt,
tgttlogo
 from
`sap-iac-test.bq_toolkit_bw7.rsbkdtp`
where objvers = 'A'
and (src like '2LIS_12_VCHDR%GS4%'
or src like '2LIS_12_VCITM%GS4%'
or src in ('ZSD_DL01', 'ZSD_DL02'))
and tgttlogo in ('CUBE', 'ODSO') -- limiting to only 2 object types as target