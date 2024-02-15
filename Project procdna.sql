-- 3. Who are the top 200 physicians that should be targeted the most? Explain the approach that you considered.	
with total_sales as 
(select physicianid,
physician_name,
speciality,
sum(jan23f + feb23f + mar23f + apr23f + may23f + jun23f) as fludara_sales,
sum(jan23m + feb23m + mar23m + apr23m + may23m + jun23m) as mercapto_sales
from physician_data
group by physicianid, physician_name, speciality)

select *, (mercapto_sales - fludara_sales) as gap 
from total_sales 
order by gap desc
limit 200;

-- creating a temporary table so that I don't have to write the queries again. 
create temporary table top_200_list as 
select * from
(with total_sales as 
(select physicianid,
physician_name,
speciality,
sum(jan23f + feb23f + mar23f + apr23f + may23f + jun23f) as fludara_sales,
sum(jan23m + feb23m + mar23m + apr23m + may23m + jun23m) as mercapto_sales
from physician_data
group by physicianid, physician_name, speciality)

select *, (mercapto_sales - fludara_sales) as gap 
from total_sales 
order by gap desc
limit 200) a; 

-- 4. How many hospitals don't have any of the top 200 target physicians affiliated to them?	

select distinct coalesce (ad.hospitalid, ad.hospital_name) as hospitals 
from top_200_list tl 
left join affliation_data ad on tl.physicianid = ad.physicianid
where hospitalid is not null or hospital_name is not null;

-- CALCULATION: unaffliated hospitals = Total hospitals - affliated hospitals = 901 - 148 = 753

-- 5. List the top 5 hospitals based on the Physicians from the following 4 specialties affiliated to them: 
-- "Hematology", "Hematology/Oncology", "Oncology Medical" and "Pediatric Hematology Oncology".		

select distinct ad.hospital_name, 
count(pd.physicianid) as no_of_phy
from physician_data pd 
join affliation_data ad on pd.physicianid = ad.physicianid 
where speciality in ('Hematology', 'Hematology/Oncology', 'Oncology Medical', 'Pediatric Hematology Oncology')
group by ad.hospital_name 
order by no_of_phy desc
limit 5;

-- 6. Calculate the Workload index for all the territories.

with total_sales as 
(select ZTT.territory_name, 
sum(jan23f + feb23f + mar23f + apr23f + may23f + jun23f + jan23m + feb23m + mar23m + apr23m + may23m + jun23m) as total_sales,
5 as num
from ZTT 
left join affliation_data ad on ZTT.zip::varchar = ad.hospital_zip
left join physician_data pd on ad.physicianid = pd.physicianid
group by ZTT.territory_name)

,sales_across_territories as 
(select sum(total_sales) as sales_across_territories, 
5 as num
from total_sales)

select ts.territory_name, 
ts.total_sales,
round(54000 * (total_sales / sales_across_territories)) as workload_index
from total_sales ts
join sales_across_territories sat on ts.num = sat.num

-- creating a temporary table of the above query

create temporary table workload_index as 
select * from 
(with total_sales as 
(select ZTT.territory_name, 
sum(jan23f + feb23f + mar23f + apr23f + may23f + jun23f + jan23m + feb23m + mar23m + apr23m + may23m + jun23m) as total_sales,
5 as num
from ZTT 
left join affliation_data ad on ZTT.zip::varchar = ad.hospital_zip
left join physician_data pd on ad.physicianid = pd.physicianid
group by ZTT.territory_name)

,sales_across_territories as 
(select sum(total_sales) as sales_across_territories, 5 as num
from total_sales)

select ts.territory_name, ts.total_sales,
round(54000 * (total_sales / sales_across_territories)) as workload_index
from total_sales ts
join sales_across_territories sat on ts.num = sat.num) a 

-- 7. Calculate the Territories above and below the balanced workload index range separately. 
-- (The territories having a workload index in the range of 700-1,300 (both inclusive) are considered to be balanced)			

select *,
case 
when workload_index between 700 and 1300 then 'Balanced'
when workload_index > 1300 then 'Above'
when workload_index < 700 then 'Below'
end as type
from workload_index