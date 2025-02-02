SELECT
  dcp_name,
  dcp_projectid,
  dcp_projectname,
  dcp_projectbrief,
  dcp_borough,
  dcp_communitydistricts,
  dcp_ulurp_nonulurp,
  dcp_leaddivision,
  dcp_ceqrtype,
  dcp_ceqrnumber,
  dcp_easeis,
  dcp_leadagencyforenvreview,
  dcp_alterationmapnumber,
  dcp_sisubdivision,
  dcp_sischoolseat,
  dcp_previousactiononsite,
  dcp_wrpnumber,
  dcp_nydospermitnumber,
  dcp_bsanumber,
  dcp_lpcnumber,
  dcp_decpermitnumber,
  dcp_femafloodzonea,
  dcp_femafloodzonecoastala,
  dcp_femafloodzonecoastala,
  dcp_femafloodzonev,

  (
  CASE
    WHEN dcp_publicstatus = 'Filed' THEN 'Filed'
    WHEN dcp_publicstatus = 'Certified' THEN 'In Public Review'
    WHEN dcp_publicstatus = 'Approved' THEN 'Completed'
    WHEN dcp_publicstatus = 'Withdrawn' THEN 'Completed'
    ELSE 'Unknown'
  END

  ) AS dcp_publicstatus_simp,

  (
    SELECT json_agg(b.dcp_bblnumber)
    FROM dcp_projectbbl b
    WHERE b.dcp_project = p.dcp_projectid
    AND b.dcp_bblnumber IS NOT NULL AND statuscode = 'Active'
  ) AS bbls,

  (
    SELECT ST_ASGeoJSON(b.polygons, 6)
    FROM project_geoms b
    WHERE b.projectid = p.dcp_name
  ) AS bbl_multipolygon,

  (
    SELECT json_agg(json_build_object(
      'dcp_name', SUBSTRING(a.dcp_name FROM '-{1}\s*(.*)'), -- use regex to pull out action name -{1}(.*)
      'actioncode', SUBSTRING(a.dcp_name FROM '^(\w+)'),
      'dcp_ulurpnumber', a.dcp_ulurpnumber,
      'dcp_prefix', a.dcp_prefix,
      'statuscode', a.statuscode,
      'dcp_ccresolutionnumber', a.dcp_ccresolutionnumber,
      'dcp_zoningresolution', z.dcp_zoningresolution
    ))
    FROM dcp_projectaction a
    LEFT JOIN dcp_zoningresolution z ON a.dcp_zoningresolution = z.dcp_zoningresolutionid
    WHERE a.dcp_project = p.dcp_projectid
      AND a.statuscode <> 'Mistake'
      AND SUBSTRING(a.dcp_name FROM '^(\w+)') IN (
        'BD',
        'BF',
        'CM',
        'CP',
        'DL',
        'DM',
        'EB',
        'EC',
        'EE',
        'EF',
        'EM',
        'EN',
        'EU',
        'GF',
        'HA',
        'HC',
        'HD',
        'HF',
        'HG',
        'HI',
        'HK',
        'HL',
        'HM',
        'HN',
        'HO',
        'HP',
        'HR',
        'HS',
        'HU',
        'HZ',
        'LD',
        'MA',
        'MC',
        'MD',
        'ME',
        'MF',
        'ML',
        'MM',
        'MP',
        'MY',
        'NP',
        'PA',
        'PC',
        'PD',
        'PE',
        'PI',
        'PL',
        'PM',
        'PN',
        'PO',
        'PP',
        'PQ',
        'PR',
        'PS',
        'PX',
        'RA',
        'RC',
        'RS',
        'SC',
        'TC',
        'TL',
        'UC',
        'VT',
        'ZA',
        'ZC',
        'ZD',
        'ZJ',
        'ZL',
        'ZM',
        'ZP',
        'ZR',
        'ZS',
        'ZX',
        'ZZ'
      )
  ) AS actions,

  (
    SELECT json_agg(json_build_object(
      'dcp_name', m.dcp_name,
      'milestonename', m.milestonename,
      'dcp_plannedstartdate', m.dcp_plannedstartdate,
      'dcp_plannedcompletiondate', m.dcp_plannedcompletiondate,
      'dcp_actualstartdate', m.dcp_actualstartdate,
      'dcp_actualenddate', m.dcp_actualenddate,
      'statuscode', m.statuscode,
      'outcome', m.outcome,

      'zap_id', m.dcp_milestone,
      'dcp_milestonesequence', m.dcp_milestonesequence,
      'display_sequence', m.display_sequence,
      'display_name', m.display_name,
      'display_date', m.display_date,
      'display_date_2', m.display_date_2,
      'display_description', m.display_description
    ))
    FROM (
      SELECT
        mm.*,
        dcp_milestone.dcp_name AS milestonename,
        dcp_milestoneoutcome.dcp_name AS outcome,
        (CASE
          WHEN mm.dcp_milestone = '780593bb-ecc2-e811-8156-1458d04d0698' THEN 58
          ELSE mm.dcp_milestonesequence
        END) AS display_sequence,

     -- The sequence number is being overidden for this 'CPC Review of Modification Scope' milestone because we want it to be inserted by date between the related city council review milestones
        (CASE
          WHEN mm.dcp_milestone = '963beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Borough Board Review'
          WHEN mm.dcp_milestone = '943beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Borough President Review'
          WHEN mm.dcp_milestone = '763beec4-dad0-e711-8116-1458d04e2fb8' THEN 'CEQR Fee Paid'
          WHEN mm.dcp_milestone = 'a63beec4-dad0-e711-8116-1458d04e2fb8' THEN 'City Council Review'
          WHEN mm.dcp_milestone = '923beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Community Board Review'
          WHEN mm.dcp_milestone = '9e3beec4-dad0-e711-8116-1458d04e2fb8' THEN 'City Planning Commission Review'
          WHEN mm.dcp_milestone = 'a43beec4-dad0-e711-8116-1458d04e2fb8' THEN 'City Planning Commission Vote'
          WHEN mm.dcp_milestone = '863beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Draft Environmental Impact Statement Public Hearing'
          WHEN mm.dcp_milestone = '7c3beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Draft Scope of Work for Environmental Impact Statement Received'
          WHEN mm.dcp_milestone = '7e3beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Environmental Impact Statement Public Scoping Meeting'
          WHEN mm.dcp_milestone = '883beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Final Environmental Impact Statement Submitted'
          WHEN mm.dcp_milestone = '783beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Environmental Assessment Statement Filed'
          WHEN mm.dcp_milestone = 'aa3beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Approval Letter Sent to Responsible Agency'
          WHEN mm.dcp_milestone = '823beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Final Scope of Work for Environmental Impact Statement Issued'
          WHEN mm.dcp_milestone = '663beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Land Use Application Filed'
          WHEN mm.dcp_milestone = '6a3beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Land Use Fee Paid'
          WHEN mm.dcp_milestone = 'a83beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Mayoral Review'
          WHEN mm.dcp_milestone = '843beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Draft Environmental Impact Statement Completed'
          WHEN mm.dcp_milestone = '8e3beec4-dad0-e711-8116-1458d04e2fb8' THEN 'Application Reviewed at City Planning Commission Review Session'
          WHEN mm.dcp_milestone = '780593bb-ecc2-e811-8156-1458d04d0698' THEN 'CPC Review of Council Modification'
        END) AS display_name,


        (CASE
          WHEN mm.dcp_milestone = '963beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = '943beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = '763beec4-dad0-e711-8116-1458d04e2fb8' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = 'a63beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = '923beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = '9e3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = 'a43beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = '863beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = '7c3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = '7e3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = '883beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = '783beec4-dad0-e711-8116-1458d04e2fb8' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = 'aa3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = '823beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = '663beec4-dad0-e711-8116-1458d04e2fb8' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = '6a3beec4-dad0-e711-8116-1458d04e2fb8' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = 'a83beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualstartdate
          WHEN mm.dcp_milestone = '843beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = '8e3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN mm.dcp_actualenddate
          WHEN mm.dcp_milestone = '780593bb-ecc2-e811-8156-1458d04d0698' THEN mm.dcp_actualenddate
          ELSE NULL
        END) AS display_date,
        -- If the project is not yet in public review, we don't want to display dates for certain milestones

        (CASE
          WHEN mm.dcp_milestone = '963beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN COALESCE(mm.dcp_actualenddate, mm.dcp_plannedcompletiondate)
          WHEN mm.dcp_milestone = '943beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN COALESCE(mm.dcp_actualenddate, mm.dcp_plannedcompletiondate)
          WHEN mm.dcp_milestone = '763beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = 'a63beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN COALESCE(mm.dcp_actualenddate, mm.dcp_plannedcompletiondate)
          WHEN mm.dcp_milestone = '923beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN COALESCE(mm.dcp_actualenddate, mm.dcp_plannedcompletiondate)
          WHEN mm.dcp_milestone = '9e3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN COALESCE(mm.dcp_actualenddate, mm.dcp_plannedcompletiondate)
          WHEN mm.dcp_milestone = 'a43beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '863beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '7c3beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '7e3beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '883beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '783beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = 'aa3beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '823beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '663beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '6a3beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = 'a83beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_publicstatus <> 'Filed' THEN COALESCE(mm.dcp_actualenddate, mm.dcp_plannedcompletiondate)
          WHEN mm.dcp_milestone = '843beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '8e3beec4-dad0-e711-8116-1458d04e2fb8' THEN NULL
          WHEN mm.dcp_milestone = '780593bb-ecc2-e811-8156-1458d04d0698' THEN NULL
          ELSE NULL
        END) AS display_date_2,
        -- display_date_2 is only populated for milestones that have date ranges. It captures the end of the date range. If the milestone is in-progress and dcp_actualenddate hasn't been populated yet, we use the planned end date instead.

        (CASE
          WHEN mm.dcp_milestone = '963beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'ULURP' THEN 'The Borough Board has 30 days concurrent with the Borough President’s review period to review the application and issue a recommendation.'
          WHEN mm.dcp_milestone = '943beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'ULURP' THEN 'The Borough President has 30 days after the Community Board issues a recommendation to review the application and issue a recommendation.'
          WHEN mm.dcp_milestone = '7c3beec4-dad0-e711-8116-1458d04e2fb8' THEN 'A Draft Scope of Work must be recieved 30 days prior to the Public Scoping Meeting.'
          WHEN mm.dcp_milestone = '883beec4-dad0-e711-8116-1458d04e2fb8' THEN 'A Final Environmental Impact Statement (FEIS) must be completed ten days prior to the City Planning Commission vote.'
          WHEN mm.dcp_milestone = 'aa3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'Non-ULURP' THEN 'For many non-ULURP actions this is the final action and record of the decision.'
          WHEN mm.dcp_milestone = 'a83beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'ULURP' THEN 'The Mayor has five days to review the City Councils decision and issue a veto.'
          WHEN mm.dcp_milestone = '843beec4-dad0-e711-8116-1458d04e2fb8' THEN 'A Draft Environmental Impact Statement must be completed prior to the City Planning Commission certifying or referring a project for public review.'

          WHEN mm.dcp_milestone = 'a63beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'ULURP' THEN 'The City Council has 50 days from receiving the City Planning Commission report to call up the application, hold a hearing and vote on the application.'
          WHEN mm.dcp_milestone = 'a63beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'Non-ULURP' THEN 'The City Council reviews text amendments and a few other non-ULURP items.'

          WHEN mm.dcp_milestone = '923beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'ULURP' THEN 'The Community Board has 60 days from the time of referral (nine days after certification) to hold a hearing and issue a recommendation.'
          WHEN mm.dcp_milestone = '923beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'Non-ULURP' THEN 'The City Planning Commission refers to the Community Board for 30, 45 or 60 days.'

          WHEN mm.dcp_milestone = '9e3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'ULURP' THEN 'The City Planning Commission has 60 days after the Borough President issues a recommendation to hold a hearing and vote on an application.'
          WHEN mm.dcp_milestone = '9e3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'Non-ULURP' THEN 'The City Planning Commission does not have a clock for non-ULURP items. It may or may not hold a hearing depending on the action.'

          WHEN mm.dcp_milestone = '8e3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'ULURP' THEN 'A "Review Session" milestone signifies that the application has been sent to the City Planning Commission (CPC) and is ready for review. The "Review" milestone represents the period of time (up to 60 days) that the CPC reviews the application before their vote.'
          WHEN mm.dcp_milestone = '8e3beec4-dad0-e711-8116-1458d04e2fb8' AND p.dcp_ulurp_nonulurp = 'Non-ULURP' THEN 'A "Review Session" milestone signifies that the application has been sent to the City Planning Commission and is ready for review. The City Planning Commission does not have a clock for non-ULURP items. It may or may not hold a hearing depending on the action.'



        END) AS display_description
        -- For some milestones, preferred the description varies depending on whether it's a ULURP project
      FROM dcp_projectmilestone mm
      LEFT JOIN dcp_milestone
        ON mm.dcp_milestone = dcp_milestone.dcp_milestoneid
      LEFT JOIN dcp_milestoneoutcome
        ON mm.dcp_milestoneoutcome = dcp_milestoneoutcomeid
      WHERE
        mm.dcp_project = p.dcp_projectid
        AND mm.statuscode <> 'Overridden'
        AND dcp_milestone.dcp_name IN (
          'Borough Board Referral',
          'Borough President Referral', 
          'Prepare CEQR Fee Payment',
          'City Council Review',
          'Community Board Referral',
          'CPC Public Meeting - Public Hearing',
          'CPC Public Meeting - Vote',
          'DEIS Public Hearing Held',
          'Review Filed EAS and EIS Draft Scope of Work',
          'DEIS Public Scoping Meeting',
          'Prepare and Review FEIS', 
          'Review Filed EAS',
          'Final Letter Sent',
          'Issue Final Scope of Work',
          'Prepare Filed Land Use Application',
          'Prepare Filed Land Use Fee Payment',
          'Mayoral Veto',
          'DEIS Notice of Completion Issued',
          'Review Session - Certified / Referred',
          'CPC Review of Modification Scope'
        )
      ORDER BY
        display_sequence,
        display_date
    ) AS m
  ) AS milestones,

  (
    SELECT json_agg(dcp_keyword.dcp_keyword)
    FROM dcp_projectkeywords k
    LEFT JOIN dcp_keyword ON k.dcp_keyword = dcp_keyword.dcp_keywordid
    WHERE k.dcp_project = p.dcp_projectid AND k.statuscode ='Active'
  ) AS keywords, -- todo:

  (
    SELECT json_agg(
      json_build_object(
        'role', pa.dcp_applicantrole,
        'name', CASE WHEN pa.dcp_name IS NOT NULL THEN pa.dcp_name ELSE account.name END
      )
    )
    FROM (
      SELECT *
      FROM dcp_projectapplicant
      WHERE dcp_project = p.dcp_projectid
        AND dcp_applicantrole IN ('Applicant', 'Co-Applicant')
        AND statuscode = 'Active'
      ORDER BY dcp_applicantrole ASC
    ) pa
    LEFT JOIN account
      ON account.accountid = pa.dcp_applicant_customer
  ) AS applicantteam,

  (
    SELECT json_agg(json_build_object(
      'dcp_validatedaddressnumber', a.dcp_validatedaddressnumber,
      'dcp_validatedstreet', a.dcp_validatedstreet
    ))
    FROM dcp_projectaddress a
    WHERE a.dcp_project = p.dcp_projectid
      AND (dcp_validatedaddressnumber IS NOT NULL AND dcp_validatedstreet IS NOT NULL AND statuscode = 'Active')
  ) AS addresses

FROM dcp_project p
WHERE dcp_name = '${id:value}'
  AND dcp_visibility = 'General Public'