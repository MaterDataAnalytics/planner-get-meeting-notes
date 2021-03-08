-- Create landing tables for MS Planner exports:
-----------Plan (16 columns)
-----------Plan Bucket (6 columns)
-----------Plan Categories (XXXXX columns)
-----------Task (21 columns)
-----------Task Assignment (10 columns)
-----------Task Checklist (13 columns )
-----------Task Post (16 columns) 
-----------TaskCategories (5 columns)
-----------TaskReferences (10 columns)
-----------User (13 columns)

USE [MDA-DB-DW-CLA-AE]
GO

create table [MDA-DB-DW-CLA-AE].[planner].[Plan]
(
PlanId varchar(100) not null
,Title nvarchar(300)
,CreatedDateTime datetime
,[Owner] varchar(100)
,CreatedByUserDisplayName nvarchar(200)
,CreatedByUserId varchar(100)
,CeatedByApplicationDisplayName nvarchar(200)
,CeatedByApplicationId varchar(100)
,LoadDate datetime not null
,InsertDate datetime
,constraint PK_planId_loadDate primary key (PlanId, LoadDate)
);

create table [MDA-DB-DW-CLA-AE].[planner].[PlanBucket]
(
PlanId varchar(100) not null
,BucketName nvarchar(100)
,OrderHint varchar(100)
,BucketId varchar(100) not null
,LoadDate datetime
,InsertDate datetime
,constraint PK_planId_bucketId_loadDate primary key (PlanId, BucketId, LoadDate)
);

create table [planner].[PlanCategory]
(
PlanId varchar(100) not null
, CategoryName varchar(100) -- Category1, Category2 ...
, CategoryTitle varchar(255) -- Action, Escalate , ...
, LoadDate datetime
, InsertDate datetime
,constraint PK_planId_loadDate primary key (PlanId, LoadDate)
);

/*
create table [MDA-DB-DW-CLA-AE].[planner].[PlanCategories]
(
PlanId varchar(100) not null
,Category1 varchar(100)
,Category2 varchar(100)
,Category3 varchar(100)
,Category4 varchar(100)
,Category5 varchar(100)
,Category6 varchar(100)
,Category7 varchar(100)
,Category8 varchar(100)
,Category9 varchar(100)
,Category10 varchar(100)
,Category11 varchar(100)
,Category12 varchar(100)
,Category13 varchar(100)
,Category14 varchar(100)
,Category15 varchar(100)
,Category16 varchar(100)
,Category17 varchar(100)
,Category18 varchar(100)
,Category19 varchar(100)
,Category20 varchar(100)
,Category21 varchar(100)
,Category22 varchar(100)
,Category23 varchar(100)
,Category24 varchar(100)
,Category25 varchar(100)
,Category26 varchar(100)
,Category27 varchar(100)
,Category28 varchar(100)
,Category29 varchar(100)
,Category30 varchar(100)
,Category31 varchar(100)
,Category32 varchar(100)
,Category33 varchar(100)
,Category34 varchar(100)
,Category35 varchar(100)
,Category36 varchar(100)
,Category37 varchar(100)
,Category38 varchar(100)
,Category39 varchar(100)
,Category40 varchar(100)
,Category41 varchar(100)
,Category42 varchar(100)
,Category43 varchar(100)
,Category44 varchar(100)
,Category45 varchar(100)
,Category46 varchar(100)
,Category47 varchar(100)
,Category48 varchar(100)
,Category49 varchar(100)
,Category50 varchar(100)
,Category51 varchar(100)
,Category52 varchar(100)
,Category53 varchar(100)
,Category54 varchar(100)
,Category55 varchar(100)
,Category56 varchar(100)
,Category57 varchar(100)
,Category58 varchar(100)
,Category59 varchar(100)
,Category60 varchar(100)
,Category61 varchar(100)
,Category62 varchar(100)
,Category63 varchar(100)
,Category64 varchar(100)
,Category65 varchar(100)
,Category66 varchar(100)
,Category67 varchar(100)
,Category68 varchar(100)
,Category69 varchar(100)
,Category70 varchar(100)
,Category71 varchar(100)
,Category72 varchar(100)
,Category73 varchar(100)
,Category74 varchar(100)
,Category75 varchar(100)
,Category76 varchar(100)
,Category77 varchar(100)
,Category78 varchar(100)
,Category79 varchar(100)
,Category80 varchar(100)
,Category81 varchar(100)
,Category82 varchar(100)
,Category83 varchar(100)
,Category84 varchar(100)
,Category85 varchar(100)
,Category86 varchar(100)
,Category87 varchar(100)
,Category88 varchar(100)
,Category89 varchar(100)
,Category90 varchar(100)
,Category91 varchar(100)
,Category92 varchar(100)
,Category93 varchar(100)
,Category94 varchar(100)
,Category95 varchar(100)
,Category96 varchar(100)
,Category97 varchar(100)
,Category98 varchar(100)
,Category99 varchar(100)
,Category100 varchar(100)
,LoadDate datetime
,InsertDate datetime
,constraint PK_planId_loadDate primary key (PlanId, LoadDate)
);
*/

create table [MDA-DB-DW-CLA-AE].[planner].[Task]
(
PlanId varchar(100) not null
,BucketId varchar(100)
,TaskId varchar(100) not null
,Title nvarchar(1000)
,OrderHint varchar(100)
,AssigneePriority nvarchar(100)
,PercentComplete int
,StartDateTime datetime
,CreatedDateTime datetime
,DueDateTime datetime
,CompletedDateTime datetime
,CompletedBy datetime
,ReferenceCount int
,ChecklistItemCount int
,ActiveChecklistItemCount int
,ConversationThreadId varchar(200)
,CreatedByUserDisplayName varchar(200)
,CreatedByUserId varchar(200)
,TaskDescription nvarchar(max)
,LoadDate datetime not null
,InsertDate datetime
,constraint PK_planId_taskId_loadDate primary key (PlanId, TaskId, LoadDate)
);

create table [MDA-DB-DW-CLA-AE].[planner].[TaskAssignment]
(
PlanId varchar(100) not null
,BucketId varchar(100)
,TaskId varchar(100) not null
,AssignedToUserId varchar(100) not null
,OrderHint varchar(100)
,AssignedDateTime datetime
,AssignedByUserDisplayName varchar(200)
,AssignedByUserId varchar(100)
,LoadDate datetime not null
,InsertDate datetime
,constraint PK_planId_taskId_loadDate_assignment primary key (PlanId, TaskId, AssignedToUserId, LoadDate)
);

create table [MDA-DB-DW-CLA-AE].[planner].[TaskChecklist]
(
PlanId varchar(100) not null
,BucketId varchar(100)
,TaskId varchar(100) not null
,Title varchar(300)
,ChecklistItemId varchar(100) not null
,isChecked bit
,ChecklistItemTitle varchar(300) 
,OrderHint varchar(100)
,LastModifiedDateTime datetime
,LastModifiedByUserDisplayName varchar(200)
,LastModifiedByUserId varchar(100)
,LoadDate datetime not null
,InsertDate datetime
,constraint PK_planId_taskId_checklistId_loadDate primary key (PlanId, TaskId, ChecklistItemId, LoadDate)
);

create table [MDA-DB-DW-CLA-AE].[planner].[TaskPost]
(
PlanId varchar(100) not null
,BucketId varchar(100)
,TaskId varchar(100) not null
,PostId varchar(300) not null
,CreatedDateTime datetime not null
,LastModifiedDateTime datetime
,ChangeKey varchar(100)
,ReceivedDateTime datetime
,HasAttachments bit
,Categories nvarchar(max)
,BodyContent nvarchar(max)
,FromName varchar(100)
,FromEmailAdress varchar(100)
,Sender nvarchar(max)
,LoadDate datetime not null
,InsertDate datetime
,constraint PK_planId_taskId_postId_loadDate primary key (PlanId, TaskId, PostId, CreatedDateTime, LoadDate)
);

create table [MDA-DB-DW-CLA-AE].[planner].[TaskCategories]
(
PlanId varchar(100) not null
,TaskId varchar(100) not null
,Category varchar(200)
,LoadDate datetime not null
,InsertDate datetime
);

create table [MDA-DB-DW-CLA-AE].[planner].[TaskReferences]
(
TaskId varchar(100) not null
,[URL] nvarchar(1000)
,HashedURL varchar(100) not null
,[Name] varchar(1000)
,[Type] varchar(100)
,LastModifiedDateTime datetime
,LastModifiedByUserDisplayName varchar(200)
,LastModifiedByUserId varchar(100)
,LoadDate datetime not null
,InsertDate datetime
,constraint PK_taskId_hashedURL_loadDate primary key (TaskId, HashedURL, LoadDate)
);

create table [MDA-DB-DW-CLA-AE].[o365].[User]
(
UserId varchar(200) not null
,DisplayName varchar(200)
,GivenName varchar(100)
,Surname varchar(100)
,Email varchar(100)
,JobTitle varchar(200)
,OfficeLocation varchar(1000)
,MobilePhone varchar(100)
,BusinessPhones varchar(1000)
,PreferredLanguage varchar(100)
,UserPrincipalName varchar(500)
,LoadDate datetime not null
,InsertDate datetime
,constraint PK_userId_loadDate_users primary key (UserId, LoadDate)
);