dcp_name,
dcp_applicant_customer,
dcp_ceqrnumber,
dcp_projectname,
dcp_projectbrief,
dcp_publicstatus_simp,
dcp_borough,
dcp_ulurp_nonulurp,
dcp_communitydistricts,
actiontypes,
dcp_certifiedreferred,
dcp_projectid,
dcp_femafloodzonea,
dcp_femafloodzonecoastala,
dcp_femafloodzoneshadedx,
dcp_femafloodzonev,
dcp_applicant,
cast(count(dcp_projectid) OVER() as integer) as total_projects,
CASE WHEN c.geom IS NOT NULL THEN true ELSE false END AS has_centroid,
string_to_array(ulurpnumbers, ';') as ulurpnumbers
