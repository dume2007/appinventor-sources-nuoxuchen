<%@page contentType="text/html" pageEncoding="UTF-8"%>
<% String gid = request.getParameter("gid"); %>
<!doctype html>
<html>
    <head>
        <meta charset="utf8">
        <title>用户列表</title>
        <script src="../jquery/jquery-3.2.1.min.js"></script>
        <script src="../jquery/jquery-ui.min.js"></script>
        <link rel="stylesheet" href="../jquery/jquery-ui.min.css">
        <link rel="stylesheet" href="../jquery/jquery.dropdown.min.css">
        <script src="../jquery/jquery.dropdown.min.js"></script>
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
             color:#FFF; font-size:16px; text-decoration:none;} 
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
            var groups = {};
            // checkbox集合
            var cb = [];
            // 选择的UID集合
            var selection = new Set();
            
            function init(){
                cb = [];
                selection.clear();
                $("#numberSelected").text(0);
                $("#filterText").val("");
                $.ajax({
                    url: root + "/api/user",
                    // JSON的内容:
                    // [{"uid":"...","lastVisited":...,"name":"...","groups":[...],"email":"..."}, ...]
                    type: "GET",
                    success: (data)=>{
                        var json = JSON.parse(data);
                        $("#content").empty();
                        for(var user of json){
                            <% if(gid != null){ %>
                                if(user["groups"].indexOf(<%=gid%>)!=-1)
                                    addRow(user);
                            <% } else { %>
                                addRow(user);
                            <% } %>
                        }
                    }
                });
            }
            
            function initGroups(){
                $.ajax({
                    url: root + "/api/user?action=listGroups",
                    type: "GET",
                    success: (data)=>{
                        groups = JSON.parse(data);
                        $("#groups").empty();
                        for(var x of groups){
                            var a = $("<a>");
                            a.attr("href", "#");
                            a.attr("gid", x["gid"]);
                            a.text(x["name"]);
                            a.click(function(){
                                addUsersToGroup($(this).attr("gid"));
                            });
                            
                            var li = $("<li>");
                            li.append(a);
                            $("#groups").append(li);
                        }
                    }
                });
            }
            
            function addRow(user){
                var tr = $("<tr>");
                // user["email"]和user["groups"]的内容作为tr元素的属性值, 便于以后获取
                tr.attr("email", user["email"]);
                tr.attr("groups", JSON.stringify(user["groups"]));
                
                var checkbox = $('<input type="checkbox" />');
                checkbox.attr("uid", user["uid"]);
                
                // 使用"this"时, 不可以使用箭头函数
                checkbox.change(function(){
                    // 由于javascript函数异步执行, 使用selection.add(user["uid"])会得到错误的结果
                    // 只能将user["uid"]的值作为checkbox元素的属性值
                    // 同理此处引用函数外变量tr也会得到错误的结果
                    var _tr = $(this).closest("tr");
                    if($(this).prop("checked")){
                        selection.add($(this).attr("uid"));
                        _tr.addClass("selected");
                    }
                    else{
                        selection.delete($(this).attr("uid"));
                        _tr.removeClass("selected");
                    }
                    $("#numberSelected").text(selection.size);
                });
                cb.push(checkbox);
                
                $("<td>").append(checkbox).appendTo(tr);
                $("<td>").text(user["email"]).appendTo(tr);
                $("<td>").text(user["name"]).appendTo(tr);
                
                // 重置密码链接
                var resetPasswordLink = $("<a>");
                resetPasswordLink.attr("href", "#");
                resetPasswordLink.attr("uid", user["uid"]);
                resetPasswordLink.attr("email", user["email"]);
                resetPasswordLink.text("重置...");
                resetPasswordLink.click(function(){
                    resetPassword($(this).attr("uid"), $(this).attr("email"));
                });
                resetPasswordLink.appendTo(tr);
                
                // 用户所属分组
                var groupCell = $("<td>");
                for(var gid of user["groups"]){
                    var a = $("<a>");
                    a.attr("href", "/usersadmin?gid=" + gid);
                    a.text(getGroupName(gid));
                    
                    groupCell.append(a);
                    groupCell.append("&nbsp;");
                }
                groupCell.appendTo(tr);
                
                // 查看用户项目链接
                var viewProjectLink = $("<a>");
                viewProjectLink.attr("href", "/projectsadmin?uid=" + user["uid"]);
                viewProjectLink.attr("target", "_blank");
                viewProjectLink.text("查看项目...");
                viewProjectLink.appendTo(tr);
                
                $("<td>").text(formatDate(user["lastVisited"])).appendTo(tr);
                
                $("#content").append(tr);
                
                // 当前行被点击时, 触发对应checkbox的click事件
                tr.click(function(){
                    $(this).find(":checkbox").trigger("click");
                });
                
                // 悬浮高亮
                tr.hover(function(){
                        $(this).addClass("hover");
                    }, 
                    function(){
                        $(this).removeClass("hover");
                    }
                );
            }
            
            function getGroupName(gid){
                for(var x of groups)
                    if(x["gid"] == gid)
                        return x["name"];
                return "";
            }
            
            function formatDate(time){
                return (time == 0) ? "未知" : new Date(time).toLocaleString();
            }
            
            function getSelectionJSON(){
                var arr = [];
                for(var x of selection)
                    arr.push(x);
                return JSON.stringify(arr);
            }
            
            $(()=>{
                init();
                initGroups();
                $("button").button();
                
                // 将当前所有可见的行选中
                $("#selectAll").click(()=>{
                    for(var i in cb)
                        if(cb[i].is(":visible")){
                            cb[i].prop("checked", true);
                            cb[i].closest("tr").addClass("selected");
                            selection.add(cb[i].attr("uid"));
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
                        chainFilter((row)=>regex.test(row.attr("email")));
                    }
                    else
                        chainFilter((row)=>row.attr("email").indexOf(text) != -1);
                });
                
                $("#resetFilter").click(()=>{
                    $("#deselectAll").trigger("click");
                    $("#filterText").val("");
                    $("#useRegex").prop("checked", false)
                    $("#content").children().show();
                });
                
                $("#addUser").click(()=>{
                    var email = prompt("输入账号名称");
                    if(!email){
                        alert("账号名称不能为空!");
                        return;
                    }
                    var name = prompt("输入显示名称", email);
                    if(!name){
                        alert("显示名称不能为空!");
                        return;
                    }
                    var password = prompt("输入密码", "123456");
                    if(!password){
                        alert("密码不能为空!");
                        return;
                    }
                    $.ajax({
                        url: root + "/api/user?action=register",
                        type: "POST",
                        data: "email=" + encodeURIComponent(email) + "&name=" + encodeURIComponent(name) + "&password=" + encodeURIComponent(password),
                        success: (data)=>{
                            if(data == "OK")
                                init();
                            else
                                alert(data);
                        }
                    });
                });
                
                $("#removeUser").click(()=>{
                    if(selection.size == 0){
                        alert("未选择用户");
                        return;
                    }
                    if(confirm("删除" + selection.size + "个用户?")){
                        var json = getSelectionJSON();
                        $.ajax({
                            url: root + "/api/admin?action=removeUsers",
                            type: "POST",
                            data: "users=" + encodeURIComponent(json),
                            success: (data)=>{
                                if(data == "OK")
                                    init();
                                else
                                    alert(data);
                            }
                        });
                    }
                });
                
                $("#createGroup").click(()=>{
                    var name = prompt("输入分组名称");
                    if(!name){
                        alert("分组名称不能为空!");
                        return;
                    }
                    $.ajax({
                        url: root + "/api/admin?action=createGroup",
                        type: "POST",
                        data: "name=" + encodeURIComponent(name),
                        success: (data)=>{
                            if(data == "OK")
                                initGroups();
                            else
                                alert(data);
                        }
                    });
                });
                
                $("#confirmImportUsers").click(()=>{
                    var files = $("#fileImportUsers").prop("files");
                    if(files.length == 0){
                        alert("未选择文件");
                        return;
                    }
                    
                    var reader = new FileReader();
                    reader.readAsText(files[0]);
                    reader.onload = (e)=>{
                        $.ajax({
                            url: root + "/api/admin?action=importUsersCSV",
                            type: "POST",
                            data: "content=" + encodeURIComponent(e.target.result),
                            success: (data)=>{
                                alert(data);
                                init();
                            }
                        });
                    };
                });
                
                $("#exportUsers").click(()=>{
                    window.open("/api/admin?action=exportUsersCSV", "_blank");
                });
                
                $("#confirmImportProject").click(()=>{
                    if(selection.size == 0){
                        alert("未选择用户");
                        return;
                    }
                    var files = $("#fileImportProject").prop("files");
                    if(files.length == 0){
                        alert("未选择文件");
                        return;
                    }
                    
                    var parts = files[0].name.split(/\./);
                    var name = parts[0];
                    var extension = parts[1];
                    if(extension != "aia"){
                        alert("文件扩展名应为aia");
                        return;
                    }
                    
                    var reader = new FileReader();
                    reader.readAsBinaryString(files[0]);
                    reader.onload = (e)=>{
                        var json = getSelectionJSON();
                        var data = btoa(e.target.result);
                        $.ajax({
                            url: root + "/api/file?action=importProject",
                            type: "POST",
                            data: "users=" + encodeURIComponent(json) + "&name=" + encodeURIComponent(name) + "&content=" + encodeURIComponent(data),
                            success: (data)=>{
                                if(data == "OK")
                                    alert("上传成功");
                            }
                        });
                    };
                });
                
                $("#exportProject").click(()=>{
                    if(selection.size == 0){
                        if(confirm("未选择用户, 是否导出所有用户的项目?"))
                            window.open("/api/file?action=exportAllProjects");
                    }
                    else{
                        var json = getSelectionJSON();
                        window.open("/api/file?action=exportAllProjects&users=" + encodeURIComponent(json));
                    }
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
            
            function resetPassword(uid, email){
                if(!confirm("为用户" + email + "重置密码?"))
                    return;
                var password = prompt("重置密码");
                if(!password){
                    alert("密码不能为空!");
                    return;
                }
                $.ajax({
                    url: root + "/api/admin?action=passwordReset",
                    type: "POST",
                    data: "uid=" + encodeURIComponent(uid) + "&password=" + encodeURIComponent(password),
                    success: (data)=>{
                        if(data == "OK")
                            init();
                        else
                            alert(data);
                    }
                });
            }
            
            function addUsersToGroup(gid){
                if(selection.size == 0){
                    alert("未选择用户");
                    return;
                }
                var json = getSelectionJSON();
                $.ajax({
                    url: root + "/api/admin?action=addUsersToGroup",
                    type: "POST",
                    data: "gid=" + gid + "&users=" + encodeURIComponent(json),
                    success: (data)=>{
                        if(data == "OK")
                            init();
                        else
                            alert(data);
                    }
                });
            }
        </script>

        <h1>用户列表</h1>
        <p>
            <button onclick="window.location.reload()">
                <span class="ui-icon ui-icon-arrowrefresh-1-s"></span>刷新
            </button>
            <button id="selectAll">全选</button>
            <button id="deselectAll">取消选择</button>
            已选择<span id="numberSelected">0</span>个用户
        </p>
        <p>
            筛选用户账号:&nbsp;<input type="text" id="filterText" class="text ui-widget-content ui-corner-all" />
            <input type="checkbox" id="useRegex"/>正则表达式
            <button id="doTextFilter" class="btn-primary">确定</button>
            <button id="resetFilter">重置</button>
        </p>
        <p>
            操作:
            <button id="addUser">
                <span class="ui-icon ui-icon-plusthick"></span>新建用户
            </button>
            <button id="removeUser">
                <span class="ui-icon ui-icon-minusthick"></span>删除用户
            </button>
            <button id="addUsersToGroup" data-jq-dropdown="#dropdown_groups">
                <span class="ui-icon-transferthick-e-w"></span>加入分组<span class="ui-icon ui-icon-triangle-1-s"></span>
            </button>
            <button id="importUsers" data-jq-dropdown="#dropdown_importUsers">
                <span class="ui-icon ui-icon-script"></span>导入用户列表
            </button>
            <button id="exportUsers">
                <span class="ui-icon ui-icon-copy"></span>导出用户列表
            </button>
            <button id="importProject" data-jq-dropdown="#dropdown_importProject">
                <span class="ui-icon ui-icon-arrowthickstop-1-n"></span>导入项目
            </button>
            <button id="exportProject">
                <span class="ui-icon ui-icon-arrowthickstop-1-s"></span>导出项目
            </button>
        </p>
        <div id="dropdown_groups" class="jq-dropdown jq-dropdown-tip">
            <ul class="jq-dropdown-menu">
                <li><a href="#" id="createGroup"><span class="ui-icon ui-icon-plusthick"></span>创建分组...</a></li>
                <li class="jq-dropdown-divider"></li>
                <div id="groups"></div>
            </ul>
        </div>
        <div id="dropdown_importUsers" class="jq-dropdown jq-dropdown-tip">
            <div class="jq-dropdown-panel">
                <input type="file" id="fileImportUsers"/>
                <button id="confirmImportUsers" class="btn-primary">确定</button>
            </div>
        </div>
        <div id="dropdown_importProject" class="jq-dropdown jq-dropdown-tip">
            <div class="jq-dropdown-panel">
                <input type="file" id="fileImportProject" accept=".aia"/>
                <button id="confirmImportProject" class="btn-primary">确定</button>
            </div>
        </div>
        <table class="ui-widget ui-widget-content ui-corner-all" style="text-align: center; width: 80%;">
            <thead>
                <tr class="ui-widget-header">
                    <th style="width: 5%">选择</th>
                    <th>账号</th>
                    <th>显示名</th>
                    <th>密码</th>
                    <th>分组</th>
                    <th>项目</th>
                    <th>最后登录时间</th>
                </tr>
            </thead>
            <tbody id="content"></tbody>
        </table>
		<p><button onclick="window.location.replace('/');">返回AppInventor</button></p>
    </body>
</html>