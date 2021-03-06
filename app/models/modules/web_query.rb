module WebQuery

  # WEB

  def self.search_arch_entity
    cleanup_query(<<EOF
select uuid, response, latestnondeletedarchent.deleted, aenttimestamp, createdAt, modifiedAt, createdBy, modifiedBy
from  latestnondeletedarchent join createdModifiedAtBy using (uuid) join latestNonDeletedArchEntFormattedIdentifiers using (uuid)
where uuid in (select uuid
      from latestnondeletedarchent join createdModifiedAtBy using (uuid) join latestnondeletedaentvalue using (uuid) left outer join vocabulary using (attributeid, vocabid)
      where (aenttypeid = :type
             or 'all' = :type)
      	 and ( 'all' = :user
      	     or createdUserid = :user
      	     or modifiedUserid = :user
      	      )
         and (freetext LIKE '%'||:query||'%'
         OR measure LIKE '%'||:query||'%'
         OR vocabname LIKE '%'||:query||'%'
         OR createdAt LIKE '%'||:query||'%'
         or createdBy LIKE '%'||:query||'%'
         or modifiedAt LIKE '%'||:query||'%'
         or modifiedBy LIKE '%'||:query||'%')
   group by uuid
   order by createdAt
      limit :limit
     offset :offset
      )
order by createdAt
;
EOF
    )
  end

  def self.total_latest_non_deleted_relationships
    cleanup_query(<<EOF
select count(*) from latestNonDeletedRelationship;
EOF
  )
  end

  def self.total_arch_entities
    cleanup_query(<<EOF
select count(*) from ArchEntity;
EOF
    )
  end

  def self.total_search_arch_entity
    cleanup_query(<<EOF
select count(uuid)
from (
select distinct uuid
      from latestnondeletedarchent join allcreatedModifiedAtBy using (uuid) join latestnondeletedaentvalue using (uuid) left outer join vocabulary using (attributeid, vocabid)
      where (aenttypeid = :type
             or 'all' = :type)
      	 and ( 'all' = :user
      	     or createdUserid = :user
      	     or modifiedUserid = :user
      	      )
         and (freetext LIKE '%'||:query||'%'
         OR measure LIKE '%'||:query||'%'
         OR vocabname LIKE '%'||:query||'%'
         OR createdAt LIKE '%'||:query||'%'
         or createdBy LIKE '%'||:query||'%'
         or modifiedAt LIKE '%'||:query||'%'
         or modifiedBy LIKE '%'||:query||'%')
   order by createdAt);
EOF
    )
  end

  def self.search_arch_entity_include_deleted
    cleanup_query(<<EOF
select uuid, response, archentity.deleted, aenttimestamp, createdAt, modifiedAt, createdBy, modifiedBy
from  (select distinct uuid, max(aenttimestamp) as aenttimestamp
      from archentity join allCreatedModifiedAtBy using (uuid) join aentvalue using (uuid) left outer join vocabulary using (attributeid, vocabid)
      where  (aenttypeid = :type
             or 'all' = :type)
      	 and ( 'all' = :user
      	     or createdUserid = :user
      	     or modifiedUserid = :user
      	      )
         and (freetext LIKE '%'||:query||'%'
         OR measure LIKE '%'||:query||'%'
         OR vocabname LIKE '%'||:query||'%'
         OR createdAt LIKE '%'||:query||'%'
         or createdBy LIKE '%'||:query||'%'
         or modifiedAt LIKE '%'||:query||'%'
         or modifiedBy LIKE '%'||:query||'%')
   group by uuid, attributeid
   having valuetimestamp = max(valuetimestamp)
   order by createdAt
      limit :limit
     offset :offset
      ) join archentity using (aenttimestamp, uuid) join allcreatedModifiedAtBy using (uuid) join latestallArchEntFormattedIdentifiers using (uuid)
order by createdAt
;
EOF
    )
  end

  def self.total_search_arch_entity_include_deleted
    cleanup_query(<<EOF
select count(uuid)
from  (select distinct uuid
      from archentity join allCreatedModifiedAtBy using (uuid) join aentvalue using (uuid) left outer join vocabulary using (attributeid, vocabid)
      where  (aenttypeid = :type
             or 'all' = :type)
      	 and ( 'all' = :user
      	     or createdUserid = :user
      	     or modifiedUserid = :user
      	      )
         and (freetext LIKE '%'||:query||'%'
         OR measure LIKE '%'||:query||'%'
         OR vocabname LIKE '%'||:query||'%'
         OR createdAt LIKE '%'||:query||'%'
         or createdBy LIKE '%'||:query||'%'
         or modifiedAt LIKE '%'||:query||'%'
         or modifiedBy LIKE '%'||:query||'%')
         group by uuid, attributeid
   		having valuetimestamp = max(valuetimestamp)
   order by createdAt
      )
;
EOF
    )
  end

  def self.get_arch_entity_deleted_status
    cleanup_query(<<EOF
    SELECT uuid, deleted from ArchEntity where uuid || aenttimestamp IN
			( SELECT uuid || max(aenttimestamp) FROM archentity WHERE uuid = ?);
EOF
    )
  end

  def self.get_arch_entity_attributes
    cleanup_query(<<EOF
SELECT uuid, attributeid, vocabid, attributename, vocabname, measure, freetext, certainty, attributetype, valuetimestamp, av.isDirty, av.isDirtyReason, attributeisfile, attributeusethumbnail
from latestnondeletedarchent
join idealaent using (aenttypeid)
join attributekey using (attributeid)
left outer join latestnondeletedaentvalue av using (uuid, attributeid)
left outer join vocabulary using (vocabid, attributeid)
where uuid = ?
order by AEntCountOrder, VocabCountOrder, valuetimestamp;
EOF
    )
  end

  def self.insert_version
    cleanup_query(<<EOF
insert into version (versionnum, uploadtimestamp, userid, ismerged) select count(*) + 1, ?, ?, 1 from version;
EOF
    )
  end

  def self.insert_arch_entity
    cleanup_query(<<EOF
INSERT INTO archentity (uuid, userid, AEntTypeID, GeoSpatialColumnType, GeoSpatialColumn, deleted, aenttimestamp, versionnum, parenttimestamp)
SELECT uuid, :userid, AEntTypeID, GeoSpatialColumnType, GeoSpatialColumn, NULL, :aenttimestamp, v.versionnum,
                                                                                                :parenttimestamp
FROM
  (SELECT uuid,
          max(aenttimestamp) AS aenttimestamp
   FROM archentity
   WHERE uuid = :uuid
   GROUP BY uuid)
JOIN archentity USING (uuid,
                       aenttimestamp),
  (SELECT versionnum
   FROM VERSION
   WHERE ismerged = 1
   ORDER BY versionnum DESC LIMIT 1) v ;
EOF
    )
  end

  def self.insert_arch_entity_attribute
    cleanup_query(<<EOF
INSERT INTO aentvalue (uuid, userid, attributeid, vocabid, measure, freetext, certainty, versionnum, parenttimestamp, valuetimestamp, deleted)
SELECT :uuid, :userid, :attributeid, :vocabid, :measure, :freetext, :certainty, v.versionnum, :parenttimestamp, :valuetimestamp, :deleted
FROM
  (SELECT versionnum
   FROM VERSION
   WHERE ismerged = 1
   ORDER BY versionnum DESC LIMIT 1) v;
EOF
    )
  end

  def self.get_arch_ent_parenttimestamp
    cleanup_query(<<EOF
SELECT max(aenttimestamp) FROM archentity WHERE uuid = ? group by uuid;
EOF
    )
  end

  def self.get_aentvalue_parenttimestamp
    cleanup_query(<<EOF
SELECT max(valuetimestamp) FROM aentvalue WHERE uuid = ? and attributeid = ? group by uuid, attributeid;
EOF
    )
  end

  def self.update_aent_value_as_dirty
    cleanup_query(<<EOF
      update aentvalue set isdirty = ?, isdirtyreason = ?
      where uuid is ? and valuetimestamp is ? and userid is ? and attributeid is ? and vocabid is ? and measure is ? and freetext is ? and certainty is ? and versionnum is ?
EOF
    )
  end

  def self.delete_or_restore_arch_entity
    cleanup_query(<<EOF
INSERT INTO archentity (uuid, userid, AEntTypeID, GeoSpatialColumnType, GeoSpatialColumn, deleted, versionnum, parentTimestamp)
SELECT uuid, :userid, AEntTypeID,
                       GeoSpatialColumnType,
                       GeoSpatialColumn,
                       :deleted,
                       v.versionnum,
                       :parenttimestamp
FROM
  (SELECT uuid,
          max(aenttimestamp) AS aenttimestamp
   FROM archentity
   WHERE uuid = :uuid
   GROUP BY uuid)
JOIN archentity USING (uuid,
                       aenttimestamp),
  (SELECT versionnum
   FROM VERSION
   WHERE ismerged = 1
   ORDER BY versionnum DESC LIMIT 1) v ;
EOF
    )
  end

  def self.get_arch_ent_info
    cleanup_query(<<EOF
select format('Last Edit by $1 $2 at $3', fname, lname, max(aenttimestamp))
  from archentity join user using (userid)
 where uuid = ?;
EOF
    )
  end

  def self.get_arch_ent_attribute_info
    cleanup_query(<<EOF
select format('Last Edit by $1 $2 at $3', fname, lname, max(valuetimestamp))
from aentvalue
join user using (userid)
where uuid = ?
  and valuetimestamp = ?
  and attributeid = ?;
EOF
    )
  end

  def self.get_arch_ent_attribute_for_comparison
    cleanup_query(<<EOF
select uuid, attributename, attributeid, attributetype, valuetimestamp, group_concat(format(formatstring, vocabname, measure, freetext, certainty), appendcharacterstring) as response, format("$1 $2", fname, lname) as modifiedBy
from latestNonDeletedArchent
join createdModifiedAtBy using (uuid)
JOIN aenttype using (aenttypeid)
JOIN idealaent using (aenttypeid)
join attributekey using (attributeid)
left outer join latestNonDeletedAentValue using (uuid, attributeid)
left outer join user on (latestNonDeletedAentValue.userid = user.userid)
left outer join vocabulary using (attributeid, vocabid)
where uuid = ?
group by uuid, attributename
order by uuid, AEntCountOrder, vocabcountorder;
EOF
    )
  end

  def self.get_arch_ent_history
    cleanup_query(<<EOF
    select uuid, aenttimestamp as tstamp
      FROM archentity
        where uuid = ?
      union
      select uuid, valuetimestamp as tstamp
        FROM aentvalue
        where uuid = ?
        group by tstamp
      order by tstamp desc;
EOF
    )
  end

  def self.get_arch_ent_attributes_at_timestamp
    cleanup_query(<<EOF
select uuid, attributename, attributeid, group_concat(DISTINCT afname || ' ' || alname) as auser, astext(transform(GeoSpatialColumn,?)),
       group_concat(DISTINCT vfname || ' ' || vlname) as vuser, aenttimestamp, valuetimestamp, max(deleted) as entityDeleted,
       group_concat(format(formatstring, vocabname, measure, freetext, certainty), appendcharacterstring) as response,
       auserid, vuserid, aentforked, avalforked, valdeleted
from  (  SELECT uuid, attributeid, GeoSpatialColumn, vocabid, aentuser.fname as afname, aentuser.lname as alname, valueuser.fname as vfname,
                valueuser.lname as vlname, attributename, vocabname, archentity.deleted, aentvalue.deleted as valdeleted, measure, freetext, certainty,
                attributetype, valuetimestamp, aenttimestamp, aentuser.userid as auserid, valueuser.userid as vuserid, archentity.isforked as aentforked,
                aentvalue.isforked as avalforked, aentcountorder, vocabcountorder, appendcharacterstring, formatstring
           FROM archentity
           join idealaent using (aenttypeid)
           JOIN attributekey USING (attributeid)
           left outer join aentvalue using (uuid, attributeid)
           LEFT OUTER JOIN vocabulary USING (vocabid, attributeid)
           JOIN (SELECT uuid, attributeid, max(valuetimestamp) as valuetimestamp
                   FROM aentvalue
                  WHERE uuid = ?
                    and valuetimestamp <= ?
               GROUP BY uuid, attributeid) USING (uuid, attributeid, valuetimestamp)
           JOIN (
                 SELECT uuid, max(aenttimestamp) as aenttimestamp
                   FROM archentity
                  WHERE uuid = ?
                    and aenttimestamp <= ?
               GROUP BY uuid) USING (uuid, aenttimestamp)
           left outer join user as aentuser on (aentuser.userid = archentity.userid)
           left outer join user as valueuser on (valueuser.userid = aentvalue.userid)
        ORDER BY uuid,  AEntCountOrder, vocabcountorder, archentity.deleted desc)
  group by uuid, attributename
  order by uuid, aentcountorder, vocabcountorder;
EOF
    )
  end

  def self.get_arch_ent_attributes_changes_at_timestamp
    cleanup_query(<<EOF
select uuid, 'EntityDeleted' as attribute, ifnull(deleted, 'Record Present') as 'What changed'
   from archentity
 where uuid = ?
   AND aenttimestamp = ?
 EXCEPT
 SELECT  uuid, 'EntityDeleted', ifnull(deleted, 'Record Present')
  from ( SELECT uuid, aenttimestamp, deleted
           FROM archentity
          where uuid = ?
            AND aenttimestamp < ?
       group by uuid
       having max(aenttimestamp)
   )
 union
 select uuid, 'geospatialcolumn', astext(transform(GeoSpatialColumn,?))
   from archentity
 where uuid = ?
   AND aenttimestamp = ?
 EXCEPT
 SELECT  uuid, 'geospatialcolumn', astext(transform(GeoSpatialColumn,?))
  from ( SELECT uuid, aenttimestamp, GeoSpatialColumn
           FROM archentity
          where uuid = ?
            AND aenttimestamp < ?
            group by uuid
       having max(aenttimestamp)
   )
 union
 select uuid, attributename, ifnull(deleted, 'Attribute Present') as 'What changed'
   from aentvalue join attributekey using (attributeid)
 where uuid = ?
   AND valuetimestamp = ?
 EXCEPT
 SELECT  uuid, attributename, ifnull(deleted, 'Attribute Present')
  from ( SELECT uuid, valuetimestamp, deleted, attributename
                 from aentvalue join attributekey using (attributeid)
       where uuid = ?
         AND valuetimestamp < ?
    group by uuid, attributeid
      having max(valuetimestamp)
   )
 union
 select uuid, attributename, group_concat(format(formatstring, vocabname, measure, freetext, certainty), appendcharacterstring) as response
   from aentvalue join attributekey using (attributeid) left outer join vocabulary using (vocabid, attributeid)
 where uuid = ?
   AND valuetimestamp = ?
 group by uuid, attributename

EXCEPT
 SELECT  uuid, attributename,  group_concat(format(formatstring, vocabname, measure, freetext, certainty), appendcharacterstring) as response
  from ( select uuid, measure , vocabname, freetext, attributename, valuetimestamp, certainty, appendcharacterstring, formatstring
           from aentvalue join attributekey using (attributeid) left outer join vocabulary using (vocabid, attributeid)
          where uuid = ?
            AND valuetimestamp < ?
       group by uuid, attributeid
       having max(valuetimestamp)
   )
  group by uuid, attributename;
EOF
    )
  end

  def self.insert_arch_ent_at_timestamp
     cleanup_query(<<EOF
INSERT INTO archentity (uuid, userid, doi, aenttypeid, deleted, versionnum, isDirty, isDirtyReason, ParentTimestamp, GeoSpatialColumnType, GeoSpatialColumn, aenttimestamp)
SELECT uuid, :userid, doi, aenttypeid, deleted, v.versionnum, isDirty, isDirtyReason, :parenttimestamp, GeoSpatialColumnType,GeoSpatialColumn, :aenttimestamp
FROM archentity
JOIN
  (SELECT uuid,
          aenttimestamp
   FROM archentity
   WHERE uuid = :uuid
     AND aenttimestamp <= :timestamp
   GROUP BY uuid HAVING max(aenttimestamp)) USING (uuid,
                                                   aenttimestamp),
  (SELECT versionnum
   FROM VERSION
   WHERE ismerged = 1
   ORDER BY versionnum DESC LIMIT 1) v ;
EOF
    )
  end


  def self.insert_aentvalue_at_timestamp
    cleanup_query(<<EOF
INSERT INTO aentvalue (uuid, userid, attributeid, vocabid, measure, freetext, certainty, deleted, versionnum, isdirty, isdirtyreason, parenttimestamp, valuetimestamp)
SELECT uuid, :userid, attributeid, vocabid, measure, freetext, certainty, deleted, v.versionnum, isdirty, isdirtyreason, :parenttimestamp, :valuetimestamp
FROM aentvalue
JOIN
  (SELECT uuid,
          valuetimestamp,
          attributeid
   FROM aentvalue
   WHERE uuid = :uuid
     AND attributeid = :attributeid
     AND valuetimestamp <= :timestamp
   GROUP BY uuid,
            attributeid HAVING MAX (valuetimestamp)) USING (uuid,
                                                            valuetimestamp,
                                                            attributeid),
  (SELECT versionnum
   FROM VERSION
   WHERE ismerged = 1
   ORDER BY versionnum DESC LIMIT 1) v;
EOF
    )
  end

  def self.get_related_arch_entities
    cleanup_query(<<EOF
SELECT uuid, relationshipid, aenttypename || ' ' || coalesce(participatesverb, 'in') || ' '|| relntypename||': '||response
FROM latestNonDeletedArchEntFormattedIdentifiers
JOIN latestnondeletedaentreln using (uuid)
join relationship using (relationshipid)
join relntype using (relntypeid)
where relationshipid in (select relationshipid
                         from latestnondeletedaentreln
                        where uuid = :uuid
                       )
and uuid != :uuid
order by aentrelntimestamp;
EOF
    )
  end

  def self.get_related_arch_entities_include_deleted
    cleanup_query(<<EOF
SELECT uuid, relationshipid, aenttypename || ' ' || coalesce(participatesverb, 'in') || ' '|| relntypename||': '||response, deletedaentreln
FROM latestNonDeletedArchEntFormattedIdentifiers
JOIN (select uuid, relationshipid, participatesverb, deleted as deletedaentreln, aentrelntimestamp from aentreln group by uuid, relationshipid having max(aentrelntimestamp)) using (uuid)
join relationship using (relationshipid)
join relntype using (relntypeid)
where relationshipid in (select relationshipid
                         from aentreln
                        where uuid = :uuid
                       )
and uuid != :uuid
order by aentrelntimestamp;
EOF
    )
  end

  def self.delete_related_arch_entity
    cleanup_query(<<EOF
update aentreln set deleted = 'true' where relationshipid = ?
EOF
    )
  end

  def self.restore_related_arch_entity
    cleanup_query(<<EOF
update aentreln set deleted = null where relationshipid = ?
EOF
    )
  end

  def self.merge_copy_arch_entity_relationships
    cleanup_query(<<EOF
insert into aentreln (UUID, RelationshipID, UserID,  ParticipatesVerb, Deleted, VersionNum, isDirty, isDirtyReason, isForked, ParentTimestamp)
  select :mergeuuid, RelationshipID, UserID, ParticipatesVerb, Deleted, VersionNum, isDirty, isDirtyReason, isForked, ParentTimestamp
  from latestnondeletedaentreln
  where uuid = :deleteuuid;
EOF
    )
  end

  def self.merge_delete_arch_entity_relationships
    cleanup_query(<<EOF
insert into aentreln (UUID, RelationshipID, UserID,  ParticipatesVerb, Deleted, VersionNum, isDirty, isDirtyReason, isForked, ParentTimestamp)
  select UUID, RelationshipID, UserID,  ParticipatesVerb, 'true' as Deleted, VersionNum, isDirty, isDirtyReason, isForked, ParentTimestamp
  from latestnondeletedaentreln
  where uuid = :deleteuuid;
EOF
    )
  end

  def self.load_relationships
    cleanup_query(<<EOF
select relationshipid, group_concat(response, ', ') as response, deleted, relntimestamp
from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                             vocabname  || ' (' || freetext || ')',
                                             vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                             freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                             vocabname,
                                             freetext), ' | ') as response, deleted, relntimestamp
      from latestNonDeletedRelnIdentifiers
      where relntypeid = :type
      group by relationshipid, attributeid
)
group by relationshipid
limit :limit
offset :offset;
EOF
    )
  end

  def self.total_relationships
    cleanup_query(<<EOF
select count(*)
from (
  select relationshipid
  from (select relationshipid, attributeid
        from latestNonDeletedRelnIdentifiers
        where relntypeid = :type
        group by relationshipid, attributeid
  )
  group by relationshipid
);
EOF
    )
  end

  def self.load_relationships_include_deleted
    cleanup_query(<<EOF
select relationshipid, group_concat(response, ', ') as response, deleted, relntimestamp
from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                             vocabname  || ' (' || freetext || ')',
                                             vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                             freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                             vocabname,
                                             freetext), ' | ') as response, deleted, relntimestamp
      from latestAllRelationshipIdentifiers
      where relntypeid = :type
      group by relationshipid, attributeid
)
group by relationshipid
limit :limit
offset :offset;
EOF
    )
  end

  def self.total_relationships_include_deleted
    cleanup_query(<<EOF
select count(*)
from (
  select relationshipid
  from (select relationshipid, attributeid
        from latestAllRelationshipIdentifiers
        where relntypeid = :type
        group by relationshipid, attributeid
  )
  group by relationshipid
);
EOF
    )
  end

  def self.load_all_relationships
    cleanup_query(<<EOF
select relationshipid, group_concat(response, ', ') as response, deleted, relntimestamp
from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                             vocabname  || ' (' || freetext || ')',
                                             vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                             freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                             vocabname,
                                             freetext), ' | ') as response, deleted, relntimestamp
      from latestNonDeletedRelnIdentifiers
      group by relationshipid, attributeid
)
group by relationshipid
limit :limit
offset :offset;
EOF
    )
  end

  def self.total_all_relationships
    cleanup_query(<<EOF
select count(*)
from (
  select relationshipid
  from (select relationshipid, attributeid
        from latestNonDeletedRelnIdentifiers
        group by relationshipid, attributeid
  )
  group by relationshipid
);
EOF
    )
  end

#   def self.load_all_relationships_include_deleted
#     cleanup_query(<<EOF
# select relationshipid, group_concat(response, ', ') as response, deleted, relntimestamp
# from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
#                                              vocabname  || ' (' || freetext || ')',
#                                              vocabname  || ' (' || (certainty * 100.0) || '% certain)',
#                                              freetext   || ' (' || (certainty * 100.0) || '% certain)',
#                                              vocabname,
#                                              freetext), ' | ') as response, deleted, relntimestamp
#         from latestAllRelationshipIdentifiers
#     group by relationshipid, attributeid
# )
# group by relationshipid
# limit :limit
# offset :offset;
# EOF
#     )
#   end

#   def self.total_all_relationships_include_deleted
#     cleanup_query(<<EOF
# select count(*)
# from (
#   select relationshipid
#   from (select relationshipid, attributeid
#           from latestAllRelationshipIdentifiers
#       group by relationshipid, attributeid
#   )
#   group by relationshipid
# );
# EOF
#     )
#   end

#   def self.search_relationship
#     cleanup_query(<<EOF
# select relationshipid, group_concat(response, ', ') as response, deleted, relntimestamp
# from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
#                                              vocabname  || ' (' || freetext || ')',
#                                              vocabname  || ' (' || (certainty * 100.0) || '% certain)',
#                                              freetext   || ' (' || (certainty * 100.0) || '% certain)',
#                                              vocabname,
#                                              freetext), ' | ') as response, deleted, relntimestamp
#       from latestNonDeletedRelnIdentifiers
#       where relationshipid in (select distinct relationshipid
#                                from latestNonDeletedRelnvalue
#                                LEFT OUTER JOIN vocabulary using (attributeid, vocabid)
#                                where (freetext LIKE '%'||:query||'%'
#                                             OR vocabname LIKE '%'||:query||'%')
#                                order by relationshipid
#                                  )
#       group by relationshipid, attributeid

# )
# group by relationshipid
# limit :limit
# offset :offset;
# EOF
#     )
#   end

#   def self.total_search_relationship
#     cleanup_query(<<EOF
# select count(*)
# from (
#   select relationshipid
#   from (select relationshipid, attributeid
#         from latestNonDeletedRelnIdentifiers
#         where relationshipid in (select distinct relationshipid
#                                  from latestNonDeletedRelnvalue
#                                  LEFT OUTER JOIN vocabulary using (attributeid, vocabid)
#                                  where (freetext LIKE '%'||:query||'%'
#                                               OR vocabname LIKE '%'||:query||'%')
#                                  order by relationshipid
#                                    )
#         group by relationshipid, attributeid

#   )
#   group by relationshipid
# );
# EOF
#     )
#   end

#   def self.search_relationship_include_deleted
#     cleanup_query(<<EOF
# select relationshipid, group_concat(response, ', ') as response, deleted, relntimestamp
# from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
#                                              vocabname  || ' (' || freetext || ')',
#                                              vocabname  || ' (' || (certainty * 100.0) || '% certain)',
#                                              freetext   || ' (' || (certainty * 100.0) || '% certain)',
#                                              vocabname,
#                                              freetext), ' | ') as response, deleted, relntimestamp
#         from latestAllRelationshipIdentifiers
#           where relationshipid in (select distinct relationshipid
#                                from relnvalue join (select relationshipid, attributeid, max(relnvaluetimestamp) as relnvaluetimestamp
#                                                       from relnvalue
#                                                       group by relationshipid, attributeid) USING (relationshipid, attributeid, relnvaluetimestamp)
#                                LEFT OUTER JOIN vocabulary using (attributeid, vocabid)
#                                where (freetext LIKE '%'||:query||'%'
#                                             OR vocabname LIKE '%'||:query||'%')
#                                order by relationshipid
#                                  )
#     group by relationshipid, attributeid

# )
# group by relationshipid
# limit :limit
# offset :offset;
# EOF
#     )
#   end

#   def self.total_search_relationship_include_deleted
#     cleanup_query(<<EOF
# select count(*)
# from (
#   select relationshipid
#   from (select relationshipid, attributeid
#           from latestAllRelationshipIdentifiers
#             where relationshipid in (select distinct relationshipid
#                                  from relnvalue join (select relationshipid, attributeid, max(relnvaluetimestamp) as relnvaluetimestamp
#                                                         from relnvalue
#                                                         group by relationshipid, attributeid) USING (relationshipid, attributeid, relnvaluetimestamp)
#                                  LEFT OUTER JOIN vocabulary using (attributeid, vocabid)
#                                  where (freetext LIKE '%'||:query||'%'
#                                               OR vocabname LIKE '%'||:query||'%')
#                                  order by relationshipid
#                                    )
#       group by relationshipid, attributeid

#   )
#   group by relationshipid
# );
# EOF
#     )
#   end

#   def self.get_rel_deleted_status
#     cleanup_query(<<EOF
#     SELECT relationshipid, deleted from relationship where relationshipid || relntimestamp IN
# 			( SELECT relationshipid || max(relntimestamp) FROM relationship WHERE relationshipid = ?);
# EOF
#     )
#   end

  def self.get_relationship_attributes
    cleanup_query(<<EOF
SELECT relationshipid, vocabid, attributeid, attributename, freetext, certainty, vocabname, relntypeid, attributetype, relnvaluetimestamp, isDirty, isDirtyReason, attributeisfile, attributeusethumbnail
    FROM relnvalue
    JOIN attributekey USING (attributeid)
    LEFT OUTER JOIN vocabulary USING (vocabid, attributeid)
    JOIN ( SELECT relationshipid, attributeid, relnvaluetimestamp, relntypeid
             FROM relnvalue
             JOIN relationship USING (relationshipid)
            WHERE relationshipid = ?
         GROUP BY relationshipid, attributeid
           HAVING MAX(relnvaluetimestamp)
              AND MAX(relntimestamp)
      ) USING (relationshipid, attributeid, relnvaluetimestamp)
   WHERE relnvalue.deleted is NULL
ORDER BY relationshipid, attributename asc;
EOF
    )
  end

#   def self.insert_relationship
#     cleanup_query(<<EOF
# INSERT INTO relationship (RelationshipID, userid, RelnTypeID, GeoSpatialColumnType, GeoSpatialColumn, deleted, relntimestamp, versionnum, parenttimestamp)
# SELECT RelationshipID, :userid, RelnTypeID, GeoSpatialColumnType, GeoSpatialColumn, NULL, :relntimestamp, v.versionnum,
#                                                                                                           :parenttimestamp
# FROM
#   (SELECT relationshipid,
#           max(relntimestamp) AS RelnTimestamp
#    FROM relationship
#    WHERE relationshipID = :relationshipid

#    GROUP BY relationshipid)
# JOIN relationship USING (relationshipid,
#                          relntimestamp),
#   (SELECT versionnum
#    FROM VERSION
#    WHERE ismerged = 1
#    ORDER BY versionnum DESC LIMIT 1) v ;
# EOF
#     )
#   end

#   def self.insert_relationship_attribute
#     cleanup_query(<<EOF
# INSERT INTO relnvalue (relationshipid, userid, attributeid, vocabid, freetext, certainty, versionnum, parenttimestamp, relnvaluetimestamp)
# SELECT :relationshipid, :userid, :attributeid, :vocabid, :freetext, :certainty, v.versionnum, :parenttimestamp, :relnvaluetimestamp
# FROM
#   (SELECT versionnum
#    FROM VERSION
#    WHERE ismerged = 1
#    ORDER BY versionnum DESC LIMIT 1) v;
# EOF
#     )
#   end

#   def self.get_rel_parenttimestamp
#     cleanup_query(<<EOF
# SELECT max(relntimestamp) FROM relationship WHERE relationshipid = ? group by relationshipid;
# EOF
#     )
#   end

#   def self.get_relnvalue_parenttimestamp
#     cleanup_query(<<EOF
# SELECT max(relnvaluetimestamp) FROM relnvalue WHERE relationshipid = ? and attributeid = ? group by relationshipid, attributeid;
# EOF
#     )
#   end

  def self.update_reln_value_as_dirty
    cleanup_query(<<EOF
      update relnvalue set isdirty = ?, isdirtyreason = ?
      where relationshipid is ? and relnvaluetimestamp is ? and userid is ? and attributeid is ? and vocabid is ? and freetext is ? and certainty is ? and versionnum is ?
EOF
    )
  end

#   def self.delete_or_restore_relationship
#     cleanup_query(<<EOF
# INSERT INTO relationship (relationshipid, userid, RelnTypeID, GeoSpatialColumnType, GeoSpatialColumn, deleted, versionnum, parentTimestamp)
# SELECT relationshipid, :userid, RelnTypeID,
#                       GeoSpatialColumnType,
#                       GeoSpatialColumn,
#                       :deleted,
#                       v.versionnum,
#                       :parenttimestamp
# FROM
#   (SELECT relationshipid,
#           max(relntimestamp) AS relntimestamp
#    FROM relationship
#    WHERE relationshipid = :relationshipid

#    GROUP BY relationshipid)
# JOIN relationship USING (relationshipid,
#                        relntimestamp),
#   (SELECT versionnum
#    FROM VERSION
#    WHERE ismerged = 1
#    ORDER BY versionnum DESC LIMIT 1) v ;
# EOF
#     )
#   end

  def self.get_rel_info
    cleanup_query(<<EOF
select 'Last Edit by: ' || fname || ' ' || lname || ' at '|| relntimestamp
from relationship
join user using(userid)
where relationshipid = ?
  and relntimestamp = ?;
EOF
    )
  end

  def self.get_rel_attribute_info
    cleanup_query(<<EOF
select 'Last Edit by: ' || fname || ' ' || lname || ' at '|| relnvaluetimestamp
from relnvalue
join user using(userid)
where relationshipid = ?
  and relnvaluetimestamp = ?
  and attributeid = ?;
EOF
    )
  end

  def self.get_rel_attribute_for_comparison
    cleanup_query(<<EOF
   select relationshipid, attributeid, attributename, attributetype,  group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                                                                         vocabname  || ' (' || freetext || ')',
                                                                                         vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                                                                         freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                                                                         vocabname,
                                                                                         freetext), ' | ') as response
from (
SELECT relationshipid, vocabid, attributeid, attributename, freetext, certainty, vocabname, relntypeid, attributetype, relnvaluetimestamp
    FROM relnvalue
    JOIN attributekey USING (attributeid)
    LEFT OUTER JOIN vocabulary USING (vocabid, attributeid)
    JOIN ( SELECT relationshipid, attributeid, relnvaluetimestamp, relntypeid
             FROM relnvalue
             JOIN relationship USING (relationshipid)
            WHERE relationship.deleted is NULL
            and relationshipid = ?
         GROUP BY relationshipid, attributeid
           HAVING MAX(relnvaluetimestamp)
              AND MAX(relntimestamp)
      ) USING (relationshipid, attributeid, relnvaluetimestamp)
   WHERE relnvalue.deleted is NULL
ORDER BY relationshipid, attributename asc)
group by relationshipid, attributename;
EOF
    )
  end

#   def self.get_rel_history
#     cleanup_query(<<EOF
#     select relationshipid, relntimestamp as tstamp
#       FROM relationship
#       where relationshipid = ?
#     union
#       select relationshipid, relnvaluetimestamp as tstamp
#         FROM relnvalue
#         where relationshipid = ?
#         group by tstamp
#         order by tstamp desc;
# EOF
#     )
#   end

  def self.get_rel_attributes_at_timestamp
    cleanup_query(<<EOF
select relationshipid, attributeid, attributename, astext(transform(GeoSpatialColumn,?)), group_concat(DISTINCT rfname || ' ' || rlname) as ruser,group_concat(DISTINCT vfname || ' ' || vlname) as rvuser, relntimestamp, relnvaluetimestamp, max(deleted), group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                                                                        vocabname  || ' (' || freetext || ')',
                                                                                        vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                                                                        freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                                                                        vocabname,
                                                                                        freetext), ' | ') as response, ruserid, rvuserid, rforked, rvforked, relnvaluedeleted
from (
SELECT relationshipid, geospatialcolumn, vocabid, attributeid, relnuser.fname as rfname, relnuser.lname as rlname, rvalueuser.fname as vfname, rvalueuser.lname as vlname, attributename, freetext, certainty, relationship.deleted, relnvalue.deleted as relnvaluedeleted, vocabname, relntypeid, attributetype, relnvaluetimestamp, relntimestamp, relnuser.userid as ruserid, rvalueuser.userid as rvuserid, relationship.isforked as rforked, relnvalue.isforked as rvforked
   FROM relnvalue
   JOIN attributekey USING (attributeid)
   LEFT OUTER JOIN vocabulary USING (vocabid, attributeid)
   join relationship using (relationshipid)
   JOIN ( SELECT relationshipid, attributeid, max(relnvaluetimestamp) as relnvaluetimestamp
            FROM relnvalue
            JOIN relationship USING (relationshipid)
           WHERE relationshipid = ?
            and relnvaluetimestamp <= ?
        GROUP BY relationshipid, attributeid
     ) USING (relationshipid, attributeid, relnvaluetimestamp)
   JOIN (select relationshipid, max(relntimestamp) as relntimestamp
         from relationship
         where relationshipid = ?
         and relntimestamp <= ?
         group by relationshipid
         ) USING (relationshipid, relntimestamp)
   left outer join user as relnuser on (relnuser.userid = relationship.userid)
   left outer join user as rvalueuser on (rvalueuser.userid = relnvalue.userid)
ORDER BY relationshipid, attributename asc)
group by relationshipid, attributename;
EOF
    )
  end

  def self.get_rel_attributes_changes_at_timestamp
    cleanup_query(<<EOF
select relationshipid, 'RelationshipDeleted' as attribute, ifnull(deleted, 'Record Present') as 'What changed'
  from relationship
where relationshipid = ?
  AND relntimestamp = ?
EXCEPT
SELECT  relationshipid, 'RelationshipDeleted', ifnull(deleted, 'Record Present')
 from ( SELECT relationshipid, relntimestamp, deleted
          FROM relationship
         where relationshipid = ?
           AND relntimestamp < ?
      group by relationshipid
      having max(relntimestamp)
  )
union
select relationshipid, 'geospatialcolumn', astext(transform(GeoSpatialColumn,?))
  from relationship
where relationshipid = ?
  AND relntimestamp = ?
EXCEPT
SELECT  relationshipid, 'geospatialcolumn', astext(transform(GeoSpatialColumn,?))
 from ( SELECT relationshipid, GeoSpatialColumn
          FROM relationship
         where relationshipid = ?
           AND relntimestamp < ?
      group by relationshipid
      having max(relntimestamp)
  )
union
select relationshipid, attributename, ifnull(deleted, 'Attribute Present') as 'What changed'
  from relnvalue join attributekey using (attributeid)
where relationshipid = ?
  AND relnvaluetimestamp = ?
except
SELECT  relationshipid, attributename, ifnull(deleted, 'Attribute Present')
 from ( SELECT relationshipid, relnvaluetimestamp, deleted, attributename
          from relnvalue join attributekey using (attributeid)
         where relationshipid = ?
           AND relnvaluetimestamp < ?
      group by relationshipid, attributeid
        having max(relnvaluetimestamp)

  )
union
select relationshipid, attributename, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                                                                         vocabname  || ' (' || freetext || ')',
                                                                                         vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                                                                         freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                                                                         vocabname,
                                                                                         freetext), ' | ') as response
  from relnvalue join attributekey using (attributeid) left outer join vocabulary using (vocabid, attributeid)
where relationshipid = ?
  AND relnvaluetimestamp = ?
group by relationshipid, attributename
EXCEPT
SELECT  relationshipid, attributename,group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                                                                         vocabname  || ' (' || freetext || ')',
                                                                                         vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                                                                         freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                                                                         vocabname,
                                                                                         freetext), ' | ') as response
 from ( select relationshipid, vocabname, freetext, attributename, relnvaluetimestamp, certainty
          from relnvalue join attributekey using (attributeid) left outer join vocabulary using (vocabid, attributeid)
         where relationshipid = ?
           AND relnvaluetimestamp < ?
      group by relationshipid, attributeid
        having max(relnvaluetimestamp)
  )
  group by relationshipid, attributename;

  ;
EOF
    )
  end

  def self.insert_rel_at_timestamp
    cleanup_query(<<EOF
INSERT INTO relationship (relationshipid, userid, relntypeid, deleted, versionnum, isDirty, isDirtyReason, ParentTimestamp, GeoSpatialColumnType, GeoSpatialColumn, relntimestamp)
SELECT relationshipid, :userid, relntypeid, deleted, v.versionnum, isDirty, isDirtyReason, :parenttimestamp, GeoSpatialColumnType,GeoSpatialColumn, :relntimestamp

FROM relationship
JOIN
  (SELECT relationshipid,
          relntimestamp
   FROM relationship
   WHERE relationshipid = :relationshipid

     AND relntimestamp <= :timestamp

   GROUP BY relationshipid HAVING max(relntimestamp)) USING (relationshipid,
                                                   relntimestamp),
  (SELECT versionnum
   FROM VERSION
   WHERE ismerged = 1
   ORDER BY versionnum DESC LIMIT 1) v;
EOF
    )
  end

  def self.insert_relnvalue_at_timestamp
    cleanup_query(<<EOF
INSERT INTO relnvalue (relationshipid, userid, attributeid, vocabid, freetext, certainty, deleted, versionnum, isdirty, isdirtyreason, parenttimestamp, relnvaluetimestamp)
SELECT relationshipid, :userid, attributeid, vocabid, freetext, certainty, deleted, v.versionnum, isdirty, isdirtyreason, :parenttimestamp, :relnvaluetimestamp

FROM relnvalue
JOIN
  (SELECT relationshipid,
          relnvaluetimestamp,
          attributeid
   FROM relnvalue
   WHERE relationshipid = :relationshipid
     AND attributeid = :attributeid
     AND relnvaluetimestamp <= :timestamp

   GROUP BY relationshipid,
            attributeid HAVING MAX (relnvaluetimestamp)) USING (relationshipid,
                                                            relnvaluetimestamp,
                                                            attributeid),
  (SELECT versionnum
   FROM VERSION
   WHERE ismerged = 1
   ORDER BY versionnum DESC LIMIT 1) v ;
EOF
    )
  end

#   def self.get_arch_entities_in_relationship
#     cleanup_query(<<EOF
# select uuid, group_concat(response, ', ') as response
# from (
#   select uuid, aenttypename, attributename, group_concat(coalesce(measure    || ' '  || vocabname  || '(' ||freetext||'; '|| (certainty * 100.0) || '% certain)',
#                                         measure    || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
#                                         vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
#                                         measure    || ' ' || vocabname   ||' ('|| (certainty * 100.0)  || '% certain)',
#                                         vocabname  || ' (' || freetext || ')',
#                                         measure    || ' (' || freetext || ')',
#                                         measure    || ' (' || (certainty * 100.0) || '% certain)',
#                                         vocabname  || ' (' || (certainty * 100.0) || '% certain)',
#                                         freetext   || ' (' || (certainty * 100.0) || '% certain)',
#                                         measure,
#                                         vocabname,
#                                         freetext), ' | ') as response, attributeid
#   from latestNonDeletedArchEntIdentifiers
#   where uuid in ( select uuid
#                     from latestNonDeletedAentReln
#                    where relationshipid = :relationshipid
#                  )

#   group by uuid, attributeid
#   order by epoch)
# group by uuid
# limit :limit
# offset :offset;
# EOF
#     )
#   end

#   def self.total_arch_entities_in_relationship
#     cleanup_query(<<EOF
# select count(*)
# from (
#   select uuid
#   from (
#     select uuid, attributeid
#     from latestNonDeletedArchEntIdentifiers
#     where uuid in ( select uuid
#                       from latestNonDeletedAentReln
#                      where relationshipid = :relationshipid
#                    )

#     group by uuid, attributeid
#     order by epoch)
#   group by uuid
# );
# EOF
#     )
#   end

#   def self.get_arch_entities_not_in_relationship
#     cleanup_query(<<EOF
# select uuid, group_concat(response, ', ') as response
# from (
#   select uuid, aenttypename, attributename, group_concat(coalesce(measure    || ' '  || vocabname  || '(' ||freetext||'; '|| (certainty * 100.0) || '% certain)',
#                                         measure    || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
#                                         vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
#                                         measure    || ' ' || vocabname   ||' ('|| (certainty * 100.0)  || '% certain)',
#                                         vocabname  || ' (' || freetext || ')',
#                                         measure    || ' (' || freetext || ')',
#                                         measure    || ' (' || (certainty * 100.0) || '% certain)',
#                                         vocabname  || ' (' || (certainty * 100.0) || '% certain)',
#                                         freetext   || ' (' || (certainty * 100.0) || '% certain)',
#                                         measure,
#                                         vocabname,
#                                         freetext), ' | ') as response, attributeid
#   from latestNonDeletedArchEntIdentifiers
#   where uuid not in ( select uuid
#                     from latestNonDeletedAentReln
#                    where relationshipid = :relationshipid
#                  )
#   and uuid in (select uuid
#                       FROM aentvalue join (select uuid, attributeid, max(valuetimestamp) as ValueTimestamp
#                                             from aentvalue
#                                         group by uuid, attributeid) USING (uuid, attributeid, valuetimestamp)
#                       LEFT OUTER JOIN vocabulary using (attributeid, vocabid)
#                      WHERE (freetext LIKE '%'||:query||'%'
#                         OR measure LIKE '%'||:query||'%'
#                         OR vocabname LIKE '%'||:query||'%')
#                      order by uuid)

#   group by uuid, attributeid
#   order by epoch)
# group by uuid
# limit :limit
# offset :offset;
# EOF
#     )
#   end

#   def self.total_arch_entities_not_in_relationship
#     cleanup_query(<<EOF
# select count(*)
# from (
#   select uuid
#   from (
#     select uuid, attributeid
#     from latestNonDeletedArchEntIdentifiers
#     where uuid not in ( select uuid
#                       from latestNonDeletedAentReln
#                      where relationshipid = :relationshipid
#                    )
#     and uuid in (select uuid
#                         FROM aentvalue join (select uuid, attributeid, max(valuetimestamp) as ValueTimestamp
#                                               from aentvalue
#                                           group by uuid, attributeid) USING (uuid, attributeid, valuetimestamp)
#                         LEFT OUTER JOIN vocabulary using (attributeid, vocabid)
#                        WHERE (freetext LIKE '%'||:query||'%'
#                           OR measure LIKE '%'||:query||'%'
#                           OR vocabname LIKE '%'||:query||'%')
#                        order by uuid)

#     group by uuid, attributeid
#     order by epoch)
#   group by uuid
# );
# EOF
#     )
#   end

#   def self.get_verbs_for_relationship
#     cleanup_query(<<EOF
# select parent from relntype where relntypeid = ? union select child from relntype where relntypeid = ?;
# EOF
#     )
  # end

#   def self.get_arch_ent_rel_parenttimestamp
#     cleanup_query(<<EOF
# SELECT max(AEntRelnTimestamp) FROM aentreln WHERE uuid = ? and relationshipid = ? group by uuid, relationshipid;
# EOF
#     )
#   end

#   def self.insert_arch_entity_relationship
#     cleanup_query(<<EOF
# INSERT INTO aentreln (UUID, RelationshipID, UserId, ParticipatesVerb, AEntRelnTimestamp, versionnum, parenttimestamp)
# SELECT :uuid, :relationshipid, :userid, :verb, :aentrelntimestamp, v.versionnum,
#                                                                    :parenttimestamp
# FROM
#   (SELECT versionnum
#    FROM VERSION
#    WHERE ismerged = 1
#    ORDER BY versionnum DESC LIMIT 1) v ;
# EOF
#     )
#   end

#   def self.delete_arch_entity_relationship
#     cleanup_query(<<EOF
# INSERT INTO aentreln (UUID, RelationshipID, UserId, Deleted, AEntRelnTimestamp, versionnum, parenttimestamp)
# SELECT :uuid, :relationshipid, :userid, 'true', :aentrelntimestamp, v.versionnum,
#                                                                     :parenttimestamp
# FROM
#   (SELECT versionnum
#    FROM VERSION
#    WHERE ismerged = 1
#    ORDER BY versionnum DESC LIMIT 1) v ;
# EOF
#     )
#   end

  def self.get_relationships_for_arch_ent
    cleanup_query(<<EOF
select relationshipid, group_concat(response, ', ') as response
from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                             vocabname  || ' (' || freetext || ')',
                                             vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                             freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                             vocabname,
                                             freetext), ' | ') as response
      from latestNonDeletedRelnIdentifiers
      where relationshipid in (select relationshipid
                                 from latestNonDeletedAentReln
                                where uuid = :uuid
                               )
      group by relationshipid, attributeid

)
group by relationshipid
limit :limit
offset :offset;
EOF
    )
  end

  def self.total_relationships_for_arch_ent
    cleanup_query(<<EOF
select count(*)
from (
  select relationshipid
  from (select relationshipid, attributeid
        from latestNonDeletedRelnIdentifiers
        where relationshipid in (select relationshipid
                                   from latestNonDeletedAentReln
                                  where uuid = :uuid
                                 )
        group by relationshipid, attributeid

  )
  group by relationshipid
);
EOF
    )
  end

  def self.get_relationships_not_belong_to_arch_ent
    cleanup_query(<<EOF
select relationshipid, group_concat(response, ', ') as response,relntypeid
from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
                                             vocabname  || ' (' || freetext || ')',
                                             vocabname  || ' (' || (certainty * 100.0) || '% certain)',
                                             freetext   || ' (' || (certainty * 100.0) || '% certain)',
                                             vocabname,
                                             freetext), ' | ') as response, relntypeid
      from latestNonDeletedRelnIdentifiers
      where relationshipid in (select distinct relationshipid
                               from latestNonDeletedRelnvalue
                               LEFT OUTER JOIN vocabulary using (attributeid, vocabid)
                               where (freetext LIKE '%'||:query||'%'
                                            OR vocabname LIKE '%'||:query||'%')
                               order by relationshipid
                                 )
      and relationshipid not in (select relationshipid
                                 from latestNonDeletedAentReln
                                where uuid = :uuid
                               )
      group by relationshipid, attributeid
)
group by relationshipid
limit :limit
offset :offset;
EOF
    )
  end

  def self.total_relationships_not_belong_to_arch_ent
    cleanup_query(<<EOF
select count(*)
from (
  select relationshipid
  from (select relationshipid, attributeid
        from latestNonDeletedRelnIdentifiers
        where relationshipid in (select distinct relationshipid
                                 from latestNonDeletedRelnvalue
                                 LEFT OUTER JOIN vocabulary using (attributeid, vocabid)
                                 where (freetext LIKE '%'||:query||'%'
                                              OR vocabname LIKE '%'||:query||'%')
                                 order by relationshipid
                                   )
        and relationshipid not in (select relationshipid
                                   from latestNonDeletedAentReln
                                  where uuid = :uuid
                                 )
        group by relationshipid, attributeid
  )
  group by relationshipid
);
EOF
    )
  end

  def self.get_vocab
    cleanup_query(<<EOF
select vocabname, vocabid, parentvocabid from vocabulary where attributeid = ?
EOF
    )
  end

  def self.get_arch_entity_types
    cleanup_query(<<EOF
select aenttypename, aenttypeid from aenttype
EOF
    )
  end

  def self.get_relationship_types
    cleanup_query(<<EOF
select relntypename, relntypeid from relntype
EOF
    )
  end

  def self.get_current_version
    cleanup_query(<<EOF
select versionnum from version where ismerged = 1 order by versionnum desc
EOF
    )
  end

  def self.get_latest_version
    cleanup_query(<<EOF
select versionnum from version order by versionnum desc
EOF
    )
  end

  def self.insert_user_version
    cleanup_query(<<EOF
insert into version (versionnum, uploadtimestamp, userid, ismerged) select count(*) + 1, ?, ?, 0 from version;
EOF
    )
  end

  def self.get_attributes_containing_vocab
    cleanup_query(<<EOF
    select attributeid, attributename
      from attributekey
      where attributeid in (select attributeid from vocabulary);
EOF
    )
  end

  def self.get_vocabs_for_attribute
    cleanup_query(<<EOF
    select attributeid, vocabid, vocabname, vocabdescription, pictureurl, parentvocabid, vocabcountorder
      from vocabulary
      where attributeid = ?
      order by vocabcountorder;
EOF
    )
  end

  def self.update_attributes_vocab
    cleanup_query(<<EOF
    insert or replace into vocabulary (vocabid, attributeid, vocabname, vocabdescription, pictureurl, parentvocabid, VocabCountOrder) VALUES(?, ?, ?, ?, ?, ?, ?);select last_insert_rowid();
EOF
    )
  end

  def self.merge_database(fromDB, version, hasPassword)
    result = "
attach database '#{fromDB}' as import;

insert or replace into archentity (
          uuid, aenttimestamp, userid, doi, aenttypeid, deleted, versionnum, isforked, parenttimestamp, geospatialcolumntype, geospatialcolumn)
   select uuid, aenttimestamp, userid, doi, aenttypeid, deleted, #{version} , a.isforked, parenttimestamp, geospatialcolumntype, geospatialcolumn
   from import.archentity
   left outer join (
    select uuid, i.aenttimestamp, 1 as isForked
      from main.archentity m join  import.archentity i using (uuid, parenttimestamp)
    where m.aenttimestamp != i.aenttimestamp) a using (uuid, aenttimestamp)
   except
   select uuid, aenttimestamp, userid, doi, aenttypeid, deleted, #{version} , isforked, parenttimestamp, geospatialcolumntype, geospatialcolumn
   from main.archentity;

 insert or replace into aentvalue (
          uuid, valuetimestamp, userid, attributeid, vocabid, freetext, measure, certainty, deleted, versionnum, isforked, parenttimestamp)
   select uuid, valuetimestamp, userid, attributeid, vocabid, freetext, measure, certainty, deleted, #{version} , a.isforked, parenttimestamp
   from import.aentvalue
   left outer join (
    select uuid, attributeid, i.valuetimestamp, 1 as isForked
      from main.aentvalue m join  import.aentvalue i using (uuid, attributeid, parenttimestamp)
    where m.valuetimestamp != i.valuetimestamp) a using (uuid, attributeid, valuetimestamp)
   except
   select uuid, valuetimestamp, userid, attributeid, vocabid, freetext, measure, certainty, deleted, #{version} , isforked, parenttimestamp
   from main.aentvalue;

 insert or replace into relationship (
          relationshipid, userid, relntimestamp, relntypeid, deleted, versionnum, isforked, parenttimestamp, geospatialcolumntype, geospatialcolumn)
   select relationshipid, userid, relntimestamp, relntypeid, deleted, #{version} , a.isforked, parenttimestamp, geospatialcolumntype, geospatialcolumn
   from import.relationship
    left outer join (
    select relationshipid, i.relntimestamp, 1 as isForked
      from main.relationship m join  import.relationship i using (relationshipid, parenttimestamp)
    where m.relntimestamp != i.relntimestamp) a using (relationshipid, relntimestamp)
   except
   select relationshipid, userid, relntimestamp, relntypeid, deleted, #{version} , isforked, parenttimestamp, geospatialcolumntype, geospatialcolumn
   from main.relationship;


 insert or replace into relnvalue (
          relationshipid, relnvaluetimestamp, userid, attributeid, vocabid, freetext, certainty, deleted, versionnum, isforked, parenttimestamp)
   select relationshipid, relnvaluetimestamp, userid, attributeid, vocabid, freetext, certainty, deleted, #{version} , a.isforked, parenttimestamp
   from import.relnvalue
   left outer join (
    select relationshipid, attributeid, i.relnvaluetimestamp, 1 as isForked
      from main.relnvalue m join  import.relnvalue i using (relationshipid, attributeid, parenttimestamp)
    where m.relnvaluetimestamp != i.relnvaluetimestamp) a using (relationshipid, attributeid, relnvaluetimestamp)
   except
   select relationshipid, relnvaluetimestamp, userid, attributeid, vocabid, freetext, certainty, deleted, #{version} , isforked, parenttimestamp
   from main.relnvalue;


 insert or replace into aentreln (
          uuid, relationshipid, userid, aentrelntimestamp, participatesverb, deleted, versionnum, isforked, parenttimestamp)
   select uuid, relationshipid, userid, aentrelntimestamp, participatesverb, deleted, #{version} , a.isforked, parenttimestamp
   from import.aentreln
  left outer join (
    select relationshipid, uuid, i.aentrelntimestamp, 1 as isForked
      from main.aentreln m join  import.aentreln i using (relationshipid, uuid, parenttimestamp)
    where m.aentrelntimestamp != i.aentrelntimestamp) a using (relationshipid, uuid, aentrelntimestamp)
   except
   select uuid, relationshipid, userid, aentrelntimestamp, participatesverb, deleted, #{version} , isforked, parenttimestamp
   from main.aentreln;

   "
   if hasPassword then
     result += "insert or replace into user (
   		      userid, fname, lname, email, UserDeleted, Password)
   				  select userid, fname, lname, email, UserDeleted, Password
   				  from import.user;"
  else
      result += "insert or replace into user (
    	        userid, fname, lname, email, UserDeleted)
    				  select userid, fname, lname, email, UserDeleted
    				  from import.user;"
  end
  result += "update version set ismerged = 1 where versionnum = #{version};

detach database import;"
    cleanup_query(result)
  end

  def self.create_full_database(toDB)
    cleanup_query(<<EOF
attach database "#{toDB}" as export;
create table export.file as select * from file;
create table export.user as select * from user;
create table export.aenttype as select * from aenttype;
create table export.attributekey as select * from attributekey;
create table export.vocabulary as select * from vocabulary;
create table export.relntype as select * from relntype;
create table export.idealaent as select * from idealaent;
create table export.idealreln as select * from idealreln;
create table export.archentity as select * from archentity;
create table export.aentvalue as select * from aentvalue;
create table export.relationship as select * from relationship;
create table export.relnvalue as select * from relnvalue;
create table export.aentreln as select * from aentreln;
EOF
    )
  end

  def self.create_sync_database_from_version(toDB, version)
    cleanup_query(<<EOF
attach database "#{toDB}" as export;
create table export.archentity as select * from archentity where versionnum >= '#{version}';
create table export.aentvalue as select * from aentvalue where versionnum >= '#{version}';
create table export.relationship as select * from relationship where versionnum >= '#{version}';
create table export.relnvalue as select * from relnvalue where versionnum >= '#{version}';
create table export.aentreln as select * from aentreln where versionnum >= '#{version}';
create table export.vocabulary as select * from vocabulary;
create table export.user as select * from user;
create table export.file as select * from file;
detach database export;
EOF
    )
  end

  def self.get_arch_entity_type
    cleanup_query(<<EOF
select aenttypename from archentity join aenttype using (aenttypeid) where uuid = ?;
EOF
    )
  end

  def self.get_relationship_type
    cleanup_query(<<EOF
select relntypename from relationship join relntype using (relntypeid) where relationshipid = ?;
EOF
    )
  end

  def self.get_aent_value
    cleanup_query(<<EOF
SELECT uuid, attributeid, attributename, vocabid, vocabname, measure, freetext, certainty, valuetimestamp, userid, versionnum
    FROM aentvalue
    JOIN attributekey USING (attributeid)
    LEFT OUTER JOIN vocabulary USING (vocabid, attributeid)
    WHERE deleted is NULL and uuid = ? and valuetimestamp = ? and attributeid = ?
 ORDER BY uuid, attributename ASC;
EOF
    )
  end

  def self.get_reln_value
    cleanup_query(<<EOF
SELECT relationshipid, attributeid, attributename, vocabid, vocabname, freetext, certainty, relnvaluetimestamp, userid, versionnum
    FROM relnvalue
    JOIN attributekey USING (attributeid)
    LEFT OUTER JOIN vocabulary USING (vocabid, attributeid)
   WHERE relnvalue.deleted is NULL and relationshipid = ? and relnvaluetimestamp = ? and attributeid = ?
ORDER BY relationshipid, attributename asc;
EOF
    )
  end

  def self.get_all_aent_values_for_version
    cleanup_query(<<EOF
SELECT uuid, valuetimestamp, attributeid
    FROM aentvalue
    JOIN attributekey USING (attributeid)
    LEFT OUTER JOIN vocabulary USING (vocabid, attributeid)
    WHERE deleted is NULL and versionnum = ?
 ORDER BY uuid, attributename ASC;
EOF
    )
  end

  def self.get_all_reln_values_for_version
    cleanup_query(<<EOF
SELECT relationshipid, relnvaluetimestamp, attributeid
    FROM relnvalue
    JOIN attributekey USING (attributeid)
    LEFT OUTER JOIN vocabulary USING (vocabid, attributeid)
   WHERE relnvalue.deleted is NULL and versionnum = ?
ORDER BY relationshipid, attributename asc;
EOF
    )
  end

  def self.has_password_column
    cleanup_query(<<EOF
SELECT sql like '%Password%' FROM sqlite_master WHERE tbl_name='User';
EOF
    )
  end

  def self.is_arch_entity_dirty
    cleanup_query(<<EOF
select sum(isdirty)
from (
  select isdirty, deleted
  from aentvalue join (
    select uuid, attributeid, max(valuetimestamp) as valuetimestamp
    from aentvalue
    where uuid = ? group by uuid, attributeid) using (uuid, attributeid, valuetimestamp)
  union
  select isdirty, deleted
  from archentity
  where uuid =  ?
  group by uuid
  having max(aenttimestamp))
where deleted is null;
EOF
    )
  end

#     def self.is_relationship_dirty
#     cleanup_query(<<EOF
# select sum(isdirty)
# from (
#   select isdirty, deleted
#   from relnvalue join (
#     select relationshipid, attributeid, max(relnvaluetimestamp) as relnvaluetimestamp
#     from relnvalue
#     where relationshipid = ? group by relationshipid, attributeid) using (relationshipid, attributeid, relnvaluetimestamp)
#   union
#   select isdirty, deleted
#   from relationship
#   where relationshipid =  ?
#   group by relationshipid
#   having max(relntimestamp))
# where deleted is null;
# EOF
#     )
#   end

  def self.get_list_of_user_emails
    cleanup_query(<<EOF
    select email from user;
EOF
    )
  end

  def self.get_user_fname
    cleanup_query(<<EOF
    select fname from user where email = ?
EOF
    )
  end

  def self.get_user_lname
    cleanup_query(<<EOF
    select lname from user where email = ?
EOF
    )
  end

  def self.get_user_password
    cleanup_query(<<EOF
    select password from user where email = ?
EOF
    )
  end

  def self.get_list_of_users
    cleanup_query(<<EOF
    select userid, fname, lname, email from user where userdeleted is NULL;
EOF
    )
  end

  def self.get_list_of_users_with_deleted
    cleanup_query(<<EOF
    select userid, fname, lname, email from user;
EOF
    )
  end

  def self.update_list_of_users
    cleanup_query(<<EOF
    replace into user (userid, fname, lname, email, userdeleted) select (select userid from user where email = :email), :firstname, :lastname, :email, null;
EOF
    )
  end

  def self.update_list_of_users_with_password
    cleanup_query(<<EOF
    replace into user (userid, fname, lname, email, password, userdeleted) select (select userid from user where email = :email), :firstname, :lastname, :email, :password, null;
EOF
    )
  end

  def self.remove_user
    cleanup_query(<<EOF
update user set userdeleted = 'true' where userid = ?;
EOF
    )
  end

  def self.is_arch_entity_forked
    cleanup_query(<<EOF
    select count(isforked) from archentity where uuid = ?;
EOF
    )
  end

  def self.is_aentvalue_forked
    cleanup_query(<<EOF
    select count(isforked) from aentvalue where uuid = ?;
EOF
    )
  end

#   def self.is_relationship_forked
#     cleanup_query(<<EOF
#     select count(isforked) from relationship where relationshipid = ?;
# EOF
#     )
#   end

#   def self.is_relnvalue_forked
#     cleanup_query(<<EOF
#     select count(isforked) from relnvalue where relationshipid = ?;
# EOF
#     )
#   end

  def self.clear_arch_ent_fork
    cleanup_query(<<EOF
    update archentity set isforked = NULL where uuid = ?;
EOF
    )
  end

  def self.clear_aentvalue_fork
    cleanup_query(<<EOF
    update aentvalue set isforked = NULL where uuid = ?;
EOF
    )
  end

#   def self.clear_rel_fork
#     cleanup_query(<<EOF
#     update relationship set isforked = NULL where relationshipid = ?;
# EOF
#     )
#   end

#   def self.clear_relnvalue_fork
#     cleanup_query(<<EOF
#     update relnvalue set isforked = NULL where relationshipid = ?;
# EOF
#     )
#   end

  def self.get_project_module_user_id
    cleanup_query(<<EOF
    select userid from user where email = ?
EOF
    )
  end

  def self.get_entity_identifier
    cleanup_query(<<EOF
select response as response
from latestAllArchEntFormattedIdentifiers
where uuid = ?
EOF
    )
  end

  def self.get_entity_uuid
    cleanup_query(<<EOF
select uuid
from latestAllArchEntFormattedIdentifiers
where response = (select response from latestAllArchEntFormattedIdentifiers where uuid = ?);
EOF
    )
  end

#   def self.get_rel_identifier
#     cleanup_query(<<EOF
# select group_concat(response, ', ') as response
# from (select relationshipid, group_concat(coalesce(vocabname  || ' (' || freetext   ||'; '|| (certainty * 100.0)  || '% certain)',
#                                              vocabname  || ' (' || freetext || ')',
#                                              vocabname  || ' (' || (certainty * 100.0) || '% certain)',
#                                              freetext   || ' (' || (certainty * 100.0) || '% certain)',
#                                              vocabname,
#                                              freetext), ' | ') as response, deleted, relntimestamp
#       from latestAllRelationshipIdentifiers
#       where relationshipid = ?
#       group by relationshipid, attributeid
# )
# group by relationshipid
# EOF
#     )
#   end

  def self.get_files_for_type
    cleanup_query(<<EOF
select Filename, MD5Checksum, Size, Type, State, Timestamp, Deleted, ThumbnailFilename, ThumbnailMD5Checksum, ThumbnailSize from File where Type = ?;
EOF
    )
  end

  def self.insert_or_update_file
    cleanup_query(<<EOF
insert or replace into File (Filename, MD5Checksum, Size, Type, State, Timestamp, Deleted, ThumbnailFilename, ThumbnailMD5Checksum, ThumbnailSize) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?); select last_insert_rowid();
EOF
    )
  end

  def self.remove_files
    cleanup_query(<<EOF
delete from File where type = ?;
EOF
    )
  end

  def self.delete_file
    cleanup_query(<<EOF
delete from File where Filename = ?;
EOF
    )
  end

  def self.delete_old_arch16n_cache_files
    cleanup_query(<<EOF
delete from File where Filename LIKE '%.properties' and Type = 'settings';
EOF
    )
  end

  def self.attribute_has_thumbnail
    cleanup_query(<<EOF
select count(*) from attributekey where attributeisfile = 1 and attributeusethumbnail = 1 and attributeid = ?;
EOF
    )
  end

  def self.attribute_is_sync
    cleanup_query(<<EOF
select count(*) from attributekey where attributeissync = 1 and attributeid = ?;
EOF
    )
  end

  def self.update_format_string
    cleanup_query(<<EOF
update attributekey set formatstring = ? where attributename = ?;
EOF
    )
  end

  def self.update_append_character_string
    cleanup_query(<<EOF
update attributekey set appendcharacterstring = ? where attributename = ?;
EOF
    )
  end

  private

  def self.cleanup_query(query)
    query.gsub("\n", " ").gsub("\t", "")
  end

end
