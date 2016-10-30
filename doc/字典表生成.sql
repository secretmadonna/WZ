Set nocount on
DECLARE @TableName nvarchar(35)
DECLARE Tbls CURSOR
FOR
    Select distinct Table_name
    FROM INFORMATION_SCHEMA.COLUMNS
    --put any exclusions here
    --where table_name not like '%old'
    order by Table_name
OPEN Tbls
PRINT '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
PRINT '<html xmlns="http://www.w3.org/1999/xhtml">'
PRINT '<head>'
PRINT '<title>数据库字典</title>'
PRINT '<style type="text/css">'
PRINT 'body{margin:0; font:11pt "arial", "微软雅黑"; cursor:default;}'
PRINT '.tableBox{margin:10px auto; padding:0px; width:1000px; height:auto; background:#FBF5E3; border:1px solid #45360A}'
PRINT '.tableBox h3 {font-size:12pt; height:30px; line-height:30px; background:#45360A; padding:0px 0px 0px 15px; color:#FFF; margin:0px; text-align:left }'
PRINT '.tableBox table {width:1000px; padding:0px }'
PRINT '.tableBox th {height:25px; border-top:1px solid #FFF; border-left:1px solid #FFF; background:#F7EBC8; border-right:1px solid #E0C889; border-bottom:1px solid #E0C889 }'
PRINT '.tableBox td {height:25px; padding-left:10px; border-top:1px solid #FFF; border-left:1px solid #FFF; border-right:1px solid #E0C889; border-bottom:1px solid #E0C889 }'
PRINT '</style>'
PRINT '</head>'
PRINT '<body>'
FETCH NEXT FROM Tbls
INTO @TableName
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '<div class="tableBox">'
    Select '<h3>' + @TableName + ' : '+cast(Value as varchar(1000)) + '</h3>'
    FROM sys.extended_properties A
    WHERE A.major_id = OBJECT_ID(@TableName)
    and name = 'MS_Description' and minor_id = 0
    PRINT '<table cellspacing="0">'
    --Get the Description of the table
    --Characters 1-250
    PRINT '<tr>' --Set up the Column Headers for the Table
    PRINT '<th>字段名称</th>'
    PRINT '<th>描述</th>'
    PRINT '<th>主键</th>'
    PRINT '<th>外键</th>'
    PRINT '<th>类型</th>'
    PRINT '<th>长度</th>'
    PRINT '<th>数值精度</th>'
    PRINT '<th>小数位数</th>'
    PRINT '<th>允许为空</th>'
    PRINT '<th>计算列</th>'
    PRINT '<th>标识列</th>'
    PRINT '<th>默认值</th>'
    --Get the Table Data
    SELECT '</tr><tr>',
    '<td>' + CAST(clmns.name AS VARCHAR(35)) + '</td>',
    '<td>' + ISNULL(CAST(exprop.value AS VARCHAR(500)),'') + '</td>',
    '<td>' + CAST(ISNULL(idxcol.index_column_id, 0)AS VARCHAR(20)) + '</td>',
    '<td>' + CAST(ISNULL(
    (SELECT TOP 1 1
    FROM sys.foreign_key_columns AS fkclmn
    WHERE fkclmn.parent_column_id = clmns.column_id
    AND fkclmn.parent_object_id = clmns.object_id
    ), 0) AS VARCHAR(20)) + '</td>',
    '<td>' + CAST(udt.name AS CHAR(15)) + '</td>' ,
    '<td>' + CAST(CAST(CASE WHEN typ.name IN (N'nchar', N'nvarchar') AND clmns.max_length <> -1
    THEN clmns.max_length/2
    ELSE clmns.max_length END AS INT) AS VARCHAR(20)) + '</td>',
    '<td>' + CAST(CAST(clmns.precision AS INT) AS VARCHAR(20)) + '</td>',
    '<td>' + CAST(CAST(clmns.scale AS INT) AS VARCHAR(20)) + '</td>',
    '<td>' + CAST(clmns.is_nullable AS VARCHAR(20)) + '</td>' ,
    '<td>' + CAST(clmns.is_computed AS VARCHAR(20)) + '</td>' ,
    '<td>' + CAST(clmns.is_identity AS VARCHAR(20)) + '</td>' ,
    '<td>' + isnull(CAST(cnstr.definition AS VARCHAR(20)),'') + '</td>'
    FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns
    ON clmns.object_id=tbl.object_id
    LEFT OUTER JOIN sys.indexes AS idx
    ON idx.object_id = clmns.object_id
    AND 1 =idx.is_primary_key
    LEFT OUTER JOIN sys.index_columns AS idxcol
    ON idxcol.index_id = idx.index_id
    AND idxcol.column_id = clmns.column_id
    AND idxcol.object_id = clmns.object_id
    AND 0 = idxcol.is_included_column
    LEFT OUTER JOIN sys.types AS udt
    ON udt.user_type_id = clmns.user_type_id
    LEFT OUTER JOIN sys.types AS typ
    ON typ.user_type_id = clmns.system_type_id
    AND typ.user_type_id = typ.system_type_id
    LEFT JOIN sys.default_constraints AS cnstr
    ON cnstr.object_id=clmns.default_object_id
    LEFT OUTER JOIN sys.extended_properties exprop
    ON exprop.major_id = clmns.object_id
    AND exprop.minor_id = clmns.column_id
    AND exprop.name = 'MS_Description'
    WHERE (tbl.name = @TableName and
    exprop.class = 1) --I don't wand to include comments on indexes
    ORDER BY clmns.column_id ASC
    PRINT '</tr></table>'
    PRINT '</div>'
    FETCH NEXT FROM Tbls
    INTO @TableName
END
PRINT '</body></HTML>'
CLOSE Tbls
DEALLOCATE Tbls