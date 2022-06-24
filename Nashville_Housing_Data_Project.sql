use [Portfolio_Project];

--selecting the data
select * from [dbo].[Portfolio_Project.dbo.NashvilleHousingData];

--Standarize the date format/ change the date col 
---time serves literally no purpose here so lets remove it

select SaleDate, cast(saledate as date) changed_to_dateonly from Portfolio_Project.dbo.NashvilleHousingData ; --convert(date, saledate) 
/*update Portfolio_Project.dbo.NashvilleHousingData
set saledate = convert(date,saledate);

alter table Portfolio_Project.dbo.NashvilleHousingData add saledateconverted date; 
update Portfolio_Project.dbo.NashvilleHousingData set saledateconverted = convert(date,saledate) */

alter table Portfolio_Project.dbo.NashvilleHousingData alter column saledate date;
select * from Portfolio_Project.dbo.NashvilleHousingData;

--Populate the property address column / fill missing  property address values
select * from Portfolio_Project.dbo.NashvilleHousingData  order by ParcelID;

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from Portfolio_Project.dbo.NashvilleHousingData a join Portfolio_Project.dbo.NashvilleHousingData b on a.parcelid = b.parcelid and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null;

update a
set a.PropertyAddress=isnull(a.PropertyAddress, b.PropertyAddress)
from Portfolio_Project.dbo.NashvilleHousingData a join Portfolio_Project.dbo.NashvilleHousingData b on a.parcelid = b.parcelid and a.[UniqueID ] <> b.[UniqueID ] 
where a.PropertyAddress is null;


--Breaking out address into individual columns (address, city, state)
select propertyaddress from Portfolio_Project.dbo.NashvilleHousingData;

/*with t as (
select [UniqueID ], [PropertyAddress], value, row_number() over(partition by uniqueid order by uniqueid) as rn from Portfolio_Project.dbo.NashvilleHousingData
cross apply string_split(propertyaddress, ','))
select [UniqueID ], [PropertyAddress],[1] as addr, [2] as cit from t
pivot(max(value) for rn in([1],[2])) as pvt_table*/

select * from Portfolio_Project.dbo.NashvilleHousingData;

select propertyaddress, SUBSTRING(propertyaddress, 1, charindex(',', propertyaddress)-1) as Address,
SUBSTRING(propertyaddress, charindex(',', propertyaddress)+1, len(propertyaddress)) as City from Portfolio_Project.dbo.NashvilleHousingData;

alter table Portfolio_Project.dbo.NashvilleHousingData add Address nvarchar(100), City varchar(50);
update Portfolio_Project.dbo.NashvilleHousingData 
set Address =SUBSTRING(propertyaddress, 1, charindex(',', propertyaddress)-1);
Portfolio_Project.dbo.NashvilleHousingData
update Portfolio_Project.dbo.NashvilleHousingData 
set City =SUBSTRING(propertyaddress, charindex(',', propertyaddress)+1, len(propertyaddress));

sp_rename 'Portfolio_Project.dbo.NashvilleHousingData.Address', 'PropertySplitAddress', 'COLUMN';
sp_rename 'Portfolio_Project.dbo.NashvilleHousingData.City', 'PropertySplitCity', 'COLUMN';


--Now same is for Owner's address
select owneraddress, parsename(replace(owneraddress,',','.'),3), parsename(replace(owneraddress,',','.'),2),
parsename(replace(owneraddress,',','.'),1) from Portfolio_Project.dbo.NashvilleHousingData;

alter table Portfolio_Project.dbo.NashvilleHousingData 
add OwnerSplitAddress varchar(255),OwnerSplitCity varchar(255),OwnerSplitState varchar(255);

update Portfolio_Project.dbo.NashvilleHousingData
set OwnerSplitAddress =parsename(replace(owneraddress,',','.'),3),
OwnerSplitCity = parsename(replace(owneraddress,',','.'),2),
OwnerSplitState =parsename(replace(owneraddress,',','.'),1);

select * from Portfolio_Project.dbo.NashvilleHousingData;


--Change Y and N to Yes and No in 'Solid as Vacant' field
select  distinct SoldAsVacant, count(*) from Portfolio_Project.dbo.NashvilleHousingData group by SoldAsVacant order by 2

select *,
case when SoldAsVacant = 'Y' then 'Yes' 
	 when SoldAsVacant ='N' then 'No' 
	 else SoldAsVacant 
	 end 
from Portfolio_Project.dbo.NashvilleHousingData 

update Portfolio_Project.dbo.NashvilleHousingData 
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes' 
	 when SoldAsVacant ='N' then 'No' 
	 else SoldAsVacant 
	 end


--Remove Duplicates

with cte_dup as
(select * from(select *, row_number() over(partition by Parcelid, propertyaddress,saledate,saleprice, legalreference order by uniqueid) as rn 
from Portfolio_Project.dbo.NashvilleHousingData) t) 
Delete from cte_dup where cte_dup.rn>1

/* delete from (select * from(select *, row_number() over(partition by Parcelid, propertyaddress,saledate,saleprice, legalreference order by uniqueid) as rn 
from Portfolio_Project.dbo.NashvilleHousingData) t) where t.rn>1 */


--Remove Duplicates
alter table Portfolio_Project.dbo.NashvilleHousingData
drop column PropertyAddress, OwnerAddress, TaxDistrict;
select * from Portfolio_Project.dbo.NashvilleHousingData