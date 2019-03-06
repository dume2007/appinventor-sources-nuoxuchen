<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!doctype html>
<%
    String uid = request.getParameter("uid");
    String gid = request.getParameter("gid");
%>
<html>
    <head>
        <meta charset="utf8">
        <title>项目列表</title>
        <script src="../jquery/jquery-3.2.1.min.js"></script>
        <script src="../jquery/jquery-ui.min.js"></script>
        <link rel="stylesheet" href="../jquery/jquery-ui.min.css">
        <style>
            .hover{background-color: #e9e9e9;}
            .selected{background-color: #0099cc;}
            .btn-primary {
                color: #fff;
                background-color: #337ab7;
                border-color: #2e6da4;
            }
            .btn-primary:focus,
            .btn-primary.focus {
                color: #fff;
                background-color: #286090;
                border-color: #122b40;
            }
            .btn-primary:hover {
                color: #fff;
                background-color: #286090;
                border-color: #204d74;
            }
            ul#nav{ width:100%; height:60px; background:#00A2CA;margin:0 auto} 
            ul#nav li{display:inline; height:60px} 
            ul#nav li a{display:inline-block; padding:0 20px; height:60px; line-height:60px;
             color:#FFF; font-size:16px;  text-decoration:none;} 
            ul#nav li a:hover{background:#0095BB}
        </style>
    </head>
    <body>
        <script>
		<%
			String  realPath  =  "\"" + "http://"  +  request.getServerName()  +  ":"  +  request.getServerPort() +"\"" ;  
			System.out.println(realPath);
		%>
            const root = 
			<%=realPath%>
            var userData;
            var cb = [];
            var selection = new Set();
            
            function initUsers(){
                $.ajax({
                    url: root + "/api/user",
                    type: "GET",
                    success: (data)=>{
                        userData = JSON.parse(data);
                        initProjects();
                    }
                });
            }
            
            function initProjects(){
                cb = [];
                selection.clear();
                $("#numberSelected").text(0);
                $("#filterText").val("");
                
                // 如果指定了uid, 只显示该用户的项目
                <% if(uid != null){ %>
                    $.ajax({
                        url: root + "/api/file?action=listUserProjects&uid=<%=uid%>",
                        // JSON的内容:
                        // [{"uid":"...","pid":...,"name":"...","dateCreated":...,"dateModified":"..."},...]
                        type: "GET",
                        success: (data)=>{
                            var projectData = JSON.parse(data);
                            $("#content").empty();
                            for(var project of projectData)
                                addRow(project);
                        }
                    });
                <% } else { %>
                    $.ajax({
                        url: root + "/api/file",
                        // JSON的内容:
                        // {"<uid>":[<project1>,<project2>,...],...}
                        type: "GET",
                        success: (data)=>{
                            var projectData = JSON.parse(data);
                            $("#content").empty();
                            for(var user of userData){
                                // 如果指定了gid参数, 仅显示分组内的用户和项目
                                <% if(gid != null){ %>
                                    if(user["groups"].indexOf(<%=gid%>) == -1)
                                        continue;
                                <% } %>
                                
                                var projects = projectData[user["uid"]];
                                for(var project of projects)
                                    addRow(project);
                            }
                        }
                    });
                <% } %>
            }
            
            function addRow(project){
                var tr = $("<tr>");
                tr.attr("name", project["name"]);
                
                var checkbox = $('<input type="checkbox" />');
                checkbox.attr("param", JSON.stringify({"uid": project["uid"], "pid": project["pid"]}));
                checkbox.change(function(){
                    var _tr = $(this).closest("tr");
                    if($(this).prop("checked")){
                        selection.add($(this).attr("param"));
                        _tr.addClass("selected");
                    }
                    else{
                        selection.delete($(this).attr("param"));
                        _tr.removeClass("selected");
                    }
                    $("#numberSelected").text(selection.size);
                });
                cb.push(checkbox);
                
                $("<td>").append(checkbox).appendTo(tr);
                $("<td>").text(getUserEmail(project["uid"])).appendTo(tr);
                $("<td>").text(project["name"]).appendTo(tr);
                
                /*var viewFileLink = $("<a>");
                viewFileLink.attr("href", "/admin/files.jsp?uid=<%=uid%>&pid=" + project["pid"]);
                viewFileLink.text("查看文件...");
                viewFileLink.appendTo(tr);*/
                
                $("<td>").text(formatDate(project["dateCreated"])).appendTo(tr);
                $("<td>").text(formatDate(project["dateModified"])).appendTo(tr);
                
                $("#content").append(tr);
                
                tr.click(function(){
                    $(this).find(":checkbox").trigger("click");
                });
                
                tr.hover(function(){
                        $(this).addClass("hover");
                    }, 
                    function(){
                        $(this).removeClass("hover");
                    }
                );
            }
            
            function getUserEmail(uid){
                for(var user of userData)
                    if(user["uid"] == uid)
                        return user["email"];
            }
            
            function formatDate(time){
                return (time == 0) ? "未知" : new Date(time).toLocaleString();
            }
            
            function getSelectionJSON(){
                var arr = [];
                for(var x of selection)
                    arr.push(JSON.parse(x));
                return JSON.stringify(arr);
            }
            
            $(()=>{
                initUsers();
                $("button").button();
                
                // 将当前所有可见的行选中
                $("#selectAll").click(()=>{
                    for(var i in cb)
                        if(cb[i].is(":visible")){
                            cb[i].prop("checked", true);
                            cb[i].closest("tr").addClass("selected");
                            selection.add(cb[i].attr("param"));
                        }
                    $("#numberSelected").text(selection.size);
                });
                
                $("#deselectAll").click(()=>{
                    for(var i in cb){
                        cb[i].prop("checked", false);
                        cb[i].closest("tr").removeClass("selected");
                    }
                    selection.clear();
                    $("#numberSelected").text(0);
                });
                
                $("#doTextFilter").click(()=>{
                    var text = $("#filterText").val();
                    if($("#useRegex").prop("checked")){
                        var regex = new RegExp(text);
                        chainFilter((row)=>regex.test(row.attr("name")));
                    }
                    else
                        chainFilter((row)=>row.attr("name").indexOf(text) != -1);
                });
                
                $("#resetFilter").click(()=>{
                    $("#deselectAll").trigger("click");
                    $("#filterText").val("");
                    $("#useRegex").prop("checked", false)
                    $("#content").children().show();
                });
                
                $("#deleteProject").click(()=>{
                    if(selection.size == 0){
                        alert("未选择项目");
                        return;
                    }
                    if(confirm("确定删除" + selection.size + "个项目?")){
                        $.ajax({
                            url: root + "/api/admin?action=deleteProjects",
                            type: "POST",
                            data: "projects=" + encodeURIComponent(getSelectionJSON()),
                            success: (data)=>{
                                if(data == "OK")
                                    initProjects();
                            }
                        });
                    }
                });
                
                $("#exportProject").click(()=>{
                    if(selection.size == 0){
                        if(confirm("未选择项目, 是否导出所有用户的项目?"))
                            window.open("/api/file?action=exportAllProjects");
                    }
                    else
                        window.open("/api/file?action=exportProjectsBatched&projects=" + encodeURIComponent(getSelectionJSON()));
                });
            });
            
            function chainFilter(filterFunc){
                $("#deselectAll").trigger("click");
                var rows = $("#content").children();
                for(var i=0;i<rows.length;i++){
                    var row = $(rows[i]);
                    if(row.is(":hidden"))
                        continue;
                    if(filterFunc(row))
                        row.show();
                    else
                        row.hide();
                }
            }
        </script>

        <h1>项目列表</h1>
        <p>
            <button onclick="window.location.reload()">
                <span class="ui-icon ui-icon-arrowrefresh-1-s"></span>刷新
            </button>
            <button id="selectAll">全选</button>
            <button id="deselectAll">取消选择</button>
            已选择<span id="numberSelected">0</span>个项目
        </p>
        <p>
            筛选项目名:&nbsp;<input type="text" id="filterText" class="text ui-widget-content ui-corner-all" />
            <input type="checkbox" id="useRegex"/>正则表达式
            <button id="doTextFilter" class="btn-primary">确定</button>
            <button id="resetFilter">重置</button>
        </p>
        <p>
            操作:
            <button id="deleteProject">
                <span class="ui-icon ui-icon-minusthick"></span>删除项目
            </button>
            <button id="exportProject">
                <span class="ui-icon ui-icon-arrowthickstop-1-s"></span>导出项目
            </button>
        </p>
        <table class="ui-widget ui-widget-content ui-corner-all" style="text-align: center; width: 80%;">
            <thead>
                <tr class="ui-widget-header">
                    <th style="width: 5%">选择</th>
                    <th>账号</th>
                    <th>项目名</th>
                    <!-- <th>文件</th> -->
                    <th>创建时间</th>
                    <th>修改时间</th>
                </tr>
            </thead>
            <tbody id="content"></tbody>
        </table>
		<p><button onclick="window.location.replace('/');">返回AppInventor</button></p>
    </body>
</html>