use Hospital; /* command to use data hospital schema for entire file */

/* Created new table to store the imported data from Business table */
CREATE TABLE hospital_dim
  (
     `ims_org_id`    VARCHAR(20),
     `business_name` VARCHAR(100),
     `bed_clusterid` INT,
     PRIMARY KEY (`ims_org_id`) /* set the ims_org_id column as primary key */
  ); 
 
 
/* Created new table to store the imported data from Bed_type table */ 
CREATE TABLE bedtype
  (
     `bed_id` INT,
     `bed_code` VARCHAR(10),
     `bed_desc` VARCHAR(100),
     PRIMARY KEY (`bed_id`) /* set the bed_id column as primary key */
  );  
 
/* Created new table to store the imported data from BedFact table */  
CREATE TABLE bed_fact
  (
     `fact_id`       INT NOT NULL auto_increment,
     `ims_org_id`    VARCHAR(20),
     `bed_id`        INT,
     `license_beds`  INT,
     `census_beds`   INT,
     `staffed_beds`  INT,
     PRIMARY KEY (`fact_id`) /* set the fact_id column as primary key */
  ); 
 
#Dimension 1
/* Store data from the hospital table to hospital_dim table */
INSERT INTO hospital_dim /* used insert command to insert the data */
            (ims_org_id,
             business_name,
             bed_clusterid)
SELECT ims_org_id,
       business_name, /* selected the underlying columns to be stored */
       bed_cluster_id
FROM   hospital;

#Dimension 2
/* Store data from the bed_type table to bedtype table */
INSERT INTO bedtype /* used insert command to insert the data */
            (bed_id,
             bed_code,
             bed_desc)
SELECT bed_id,
       bed_code, /* selected the underlying columns to be stored */
       bed_desc
FROM   bed_type;

#Fact
/* Store data from the bedfact table to bed_fact table */
INSERT INTO bed_fact
            (ims_org_id,
             bed_id,
             license_beds, /* used insert command to insert the data */
             census_beds,
             staffed_beds)
SELECT bd.ims_org_id,
       bd.bed_id,
       bd.license_beds, /* selected the underlying columns to be stored */
       bd.census_beds,
       bd.staffed_beds
FROM   bedfact BD;

CREATE VIEW beddetails /* Created a view to store number of different bed counts which will be used in all three  queries */
AS
  SELECT ims_org_id,
         Sum(icu_licensed)      AS icu_licensed, /* total of ICU licensed beds*/
         Sum(sicu_licensed)     AS sicu_licensed, /* total of SICU licensed beds*/
         Sum(icu_census_beds)   AS icu_census_beds, /* total of ICU census beds*/
         Sum(sicu_census_beds)  AS sicu_census_beds, /* total of SICU census beds*/
         Sum(icu_staffed_beds)  AS icu_staffed_beds, /* total of ICU staffed beds*/
         Sum(sicu_staffed_beds) AS sicu_staffed_beds /* total of SICU staffed beds*/
  FROM   (SELECT ims_org_id,
                 CASE
                   WHEN bt.bed_desc = 'ICU' THEN license_beds /* added condition to show number of licensed beds when bed type is ICU */
                   ELSE 0 /* if above condition not satisfied set value as 0 */
                 END AS icu_licensed,
                 CASE
                   WHEN bt.bed_desc = 'SICU' THEN license_beds /* added condition to show number of licensed beds when bed type is SICU */
                   ELSE 0 /* if above condition not satisfied set value as 0 */
                 END AS sicu_licensed,
                 CASE
                   WHEN bt.bed_desc = 'ICU' THEN census_beds /* added condition to show number of census beds when bed type is ICU */
                   ELSE 0 /* if above condition not satisfied set value as 0 */
                 END AS icu_census_beds,
                 CASE
                   WHEN bt.bed_desc = 'SICU' THEN census_beds /* added condition to show number of census beds when bed type is SICU */
                   ELSE 0 /* if above condition not satisfied set value as 0 */
                 END AS sicu_census_beds,
                 CASE
                   WHEN bt.bed_desc = 'ICU' THEN staffed_beds /* added condition to show number of staffed beds when bed type is ICU */
                   ELSE 0 /* if above condition not satisfied set value as 0 */
                 END AS icu_staffed_beds,
                 CASE
                   WHEN bt.bed_desc = 'SICU' THEN staffed_beds  /* added condition to show number of staffed beds when bed type is SICU */
                   ELSE 0 /* if above condition not satisfied set value as 0 */
                 END AS sicu_staffed_beds
          FROM   bed_fact bf
                 INNER JOIN bedtype bt
                         ON bt.bed_id = bf.bed_id /* joined the fact table with bedtype table to get the bed type description */
          WHERE  bed_desc IN ( 'ICU', 'SICU' )) AS T /* added a condition to consider only ICU and SICU beds */
  GROUP  BY ims_org_id; /* grouped data on hospitalID */


# TOP 10 HOSPITALS WITH LICENSED BEDS
SELECT hd.ims_org_id,
       hd.business_name,
       icu_licensed,
       sicu_licensed, /* selected all the required columns */
       icu_census_beds,
       sicu_census_beds,
       icu_staffed_beds,
       sicu_staffed_beds
FROM   (SELECT ims_org_id,
               Sum(license_beds) AS license_beds /* total of ICU and SICU licensed beds*/
        FROM   bed_fact
        WHERE  bed_id IN ( 4, 15 ) /* added a condition to consider only ICU and SICU beds */
        GROUP  BY ims_org_id /* grouped data on hospitalID */
        ORDER  BY license_beds DESC /* ordered data on the basis of number of licensed beds in descending order */
        LIMIT  10) SummaryLicensed /* Gave a limit to show only top 10 records */
       INNER JOIN (SELECT ims_org_id,
                          icu_licensed,
                          sicu_licensed,
                          icu_census_beds,  /* selected all the required columns */
                          sicu_census_beds,
                          icu_staffed_beds,
                          sicu_staffed_beds
                   FROM   beddetails) LicensedDetail
               ON SummaryLicensed.ims_org_id = LicensedDetail.ims_org_id /* got the top 10 hospitals so added this join to show their detailed number of different bed type records */
       INNER JOIN hospital_dim HD
               ON LicensedDetail.ims_org_id = hd.ims_org_id /* added this join to show the hospital name */
ORDER  BY license_beds DESC; /* ordered data on the basis of number of licensed beds in descending order */

# TOP 10 HOSPITALS WITH CENSUS BEDS
SELECT hd.ims_org_id,
       hd.business_name,
       icu_licensed, /* selected all the required columns */
       sicu_licensed,
       icu_census_beds,
       sicu_census_beds,
       icu_staffed_beds,
       sicu_staffed_beds
FROM   (SELECT ims_org_id,
               Sum(census_beds) AS census_beds /* total of ICU and SICU census beds*/
        FROM   bed_fact
        WHERE  bed_id IN ( 4, 15 ) /* added a condition to consider only ICU and SICU beds */
        GROUP  BY ims_org_id  /* grouped data on hospitalID */
        ORDER  BY census_beds DESC /* ordered data on the basis of number of census beds in descending order */
        LIMIT  10) SummaryCensus /* Gave a limit to show only top 10 records */
       INNER JOIN (SELECT ims_org_id,
                          icu_licensed,
                          sicu_licensed,
                          icu_census_beds,  /* selected all the required columns */
                          sicu_census_beds,
                          icu_staffed_beds,
                          sicu_staffed_beds
                   FROM   beddetails) LicensedDetail
               ON LicensedDetail.ims_org_id = SummaryCensus.ims_org_id /* got the top 10 hospitals so added this join to show their detailed number of different bed type records */
       INNER JOIN hospital_dim HD
               ON LicensedDetail.ims_org_id = hd.ims_org_id /* added this join to show the hospital name */
ORDER  BY census_beds DESC; /* ordered data on the basis of number of census beds in descending order */
 

# TOP 10 HOSPITALS WITH STAFFED BEDS
SELECT hd.ims_org_id,
       hd.business_name,
       icu_licensed,
       sicu_licensed,
       icu_census_beds, /* selected all the required columns */
       sicu_census_beds,
       icu_staffed_beds,
       sicu_staffed_beds
FROM   (SELECT ims_org_id,
               Sum(staffed_beds) AS staffed_beds /* total of ICU and SICU staffed beds*/
        FROM   bed_fact
        WHERE  bed_id IN ( 4, 15 ) /* added a condition to consider only ICU and SICU beds */
        GROUP  BY ims_org_id /* grouped data on hospitalID */
        ORDER  BY staffed_beds DESC /* ordered data on the basis of number of staffed beds in descending order */
        LIMIT  10) SummaryStaffed /* Gave a limit to show only top 10 records */
       INNER JOIN (SELECT ims_org_id,
                          icu_licensed,
                          sicu_licensed,  /* selected all the required columns */
                          icu_census_beds,
                          sicu_census_beds,
                          icu_staffed_beds,
                          sicu_staffed_beds
                   FROM   beddetails) LicensedDetail
               ON LicensedDetail.ims_org_id = SummaryStaffed.ims_org_id /* got the top 10 hospitals so added this join to show their detailed number of different bed type records */
       INNER JOIN hospital_dim HD
               ON LicensedDetail.ims_org_id = hd.ims_org_id  /* added this join to show the hospital name */
ORDER  BY staffed_beds DESC /* ordered data on the basis of number of census beds in descending order */ ; 



