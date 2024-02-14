--EXPLORATORY QUERY

SELECT * 
FROM  fips_county --cbsa --prescription 
--WHERE total_claim_count <> total_claim_count_ge65
LIMIT 10

-- 1a. Which prescriber had the highest total number of claims totaled over all drugs? Report the npi and the total number of claims.

SELECT 
	t1.npi as npi, 
	--t1.nppes_provider_last_org_name as last_name_or_organization, 
	--t1.nppes_provider_first_name as first_name, 
	SUM(t2.total_claim_count) as total_claims
FROM prescriber as t1
INNER JOIN prescription as t2
	ON t1.npi = t2.npi
GROUP BY t1.npi, last_name_or_organization, first_name
ORDER BY total_claims DESC
LIMIT 1;

--Answer: Bruce Pendley, NPI 1881634483, had the highest total number of claims with 99,707
    
-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT 
	t1.npi as npi, 
	t1.nppes_provider_last_org_name as last_name_or_organization, 
	t1.nppes_provider_first_name as first_name,
	t1.specialty_description,
	SUM(t2.total_claim_count) as total_claims
FROM prescriber as t1
INNER JOIN prescription as t2
	ON t1.npi = t2.npi
GROUP BY t1.npi, last_name_or_organization, first_name, t1.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--Answer:
	-- NPI: 1881634483
	-- Name: Bruce Pendley
	-- Specialty: Family Practice
	-- Total Claims: 9970
	
-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT 
	t1.specialty_description,
	SUM(t2.total_claim_count) as total_claims
FROM prescriber as t1
INNER JOIN prescription as t2
	ON t1.npi = t2.npi
GROUP BY t1.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--Answer: Family Practice with 9,752,347 claims.

--2b. Which specialty had the most total number of claims for opioids?

SELECT 
	t1.specialty_description,
	SUM(t2.total_claim_count) as total_opioid_claims
FROM prescriber as t1
INNER JOIN prescription as t2
	ON t1.npi = t2.npi
INNER JOIN drug as t3
	ON t2.drug_name = t3.drug_name
WHERE t3.opioid_drug_flag = 'Y'
GROUP BY t1.specialty_description
ORDER BY total_opioid_claims DESC
LIMIT 1;

-- Answer: Nurse Practitioner with 900,845 total opioid claims

--2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT 
	t1.specialty_description,
	SUM(t2.total_claim_count) as total_claims
FROM prescriber as t1
LEFT JOIN prescription as t2
	ON t1.npi = t2.npi
GROUP BY t1.specialty_description
HAVING (SUM(t2.total_claim_count) IS NULL 
		OR SUM(t2.total_claim_count) = 0);
		
-- Answer: Yes. There are 15 specialties with no perscriptions.
-- "Marriage & Family Therapist"
-- "Contractor"
-- "Physical Therapist in Private Practice"
-- "Developmental Therapist"
-- "Radiology Practitioner Assistant"
-- "Hospital"
-- "Specialist/Technologist, Other"
-- "Chiropractic"
-- "Occupational Therapist in Private Practice"
-- "Licensed Practical Nurse"
-- "Midwife"
-- "Medical Genetics"
-- "Physical Therapy Assistant"
-- "Ambulatory Surgical Center"
-- "Undefined Physician type"

--2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3a. Which drug (generic_name) had the highest total drug cost?
-- Note: Per Robert, "highest total drug cost" indicates sum of all tota_drug_costs, not the max value for total_drug_cost.

SELECT t1.generic_name, SUM(t2.total_drug_cost) as total_drug_cost
	FROM drug as t1
RIGHT JOIN prescription as t2
	ON t1.drug_name = t2.drug_name
GROUP BY t1.generic_name
ORDER BY SUM(t2.total_drug_cost) DESC;

--Answer: "INSULIN GLARGINE,HUM.REC.ANLOG" has the highest total drug cost with $104,264,066.35

-- 3b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT t1.generic_name, SUM(t2.total_drug_cost) as total_drug_cost, SUM(t2.total_day_supply) as total_drug_cost, ROUND((SUM(t2.total_drug_cost)/SUM(t2.total_day_supply)),2) as drug_cost_per_day
	FROM drug as t1
RIGHT JOIN prescription as t2
	ON t1.drug_name = t2.drug_name
GROUP BY t1.generic_name
ORDER BY drug_cost_per_day DESC;

--Answer: "C1 ESTERASE INHIBITOR" has the highest cost per day at $3,495.22

-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT t1.drug_name, 
	CASE WHEN t1.opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN t1.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS opioid_or_antibiotic
FROM drug as t1

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	CASE WHEN t1.opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN t1.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS opioid_or_antibiotic,
	CAST(SUM(t2.total_drug_cost)AS MONEY) as total_drug_cost
FROM drug as t1
INNER JOIN prescription as t2
	ON t1.drug_name = t2.drug_name
GROUP BY opioid_or_antibiotic
ORDER BY total_drug_cost DESC;

--Answer: More was spent on opioids ($105,080,626.37) than antibiotics ($38,435,121.26)

-- 5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT t2.state, COUNT(DISTINCT t1.cbsaname)
FROM cbsa as t1
INNER JOIN fips_county as t2
	ON t1.fipscounty = t2.fipscounty
WHERE t2.state = 'TN'
GROUP BY t2.state;

--Answer: 10 CBSAs are in Tennessee.

--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT t1.cbsaname as cbsa_name, SUM(t3.population) as total_population
FROM cbsa as t1
INNER JOIN fips_county as t2
	ON t1.fipscounty = t2.fipscounty
INNER JOIN population as t3
	ON t2.fipscounty = t3.fipscounty
GROUP BY cbsa_name
ORDER BY total_population DESC;

--Answer: Largest population is "Nashville-Davidson--Murfreesboro--Franklin, TN" (1,830,410)
--        Smallest population is "Morristown, TN" (116,352)

--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT t2.county, t1.cbsaname as cbsa_name, SUM(t3.population) as total_population
FROM cbsa as t1
RIGHT JOIN fips_county as t2
	ON t1.fipscounty = t2.fipscounty
INNER JOIN population as t3
	ON t2.fipscounty = t3.fipscounty
WHERE t1.cbsa IS NULL
GROUP BY t2.county, cbsa_name
ORDER BY total_population DESC;

--Answer: Sevier county, population 95,523

-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

-- SELECT t1.drug_name, SUM(total_claim_count)
-- FROM drug as t1
-- INNER JOIN prescription as t2

--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.