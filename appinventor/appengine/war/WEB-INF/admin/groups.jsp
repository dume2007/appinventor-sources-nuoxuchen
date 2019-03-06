<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!doctype html>
<html>
    <head>
        <meta charset="utf8">
        <title>分组列表</title>
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
            var selected;
            
            function init(){
                selected = undefined;
                $(".selected").removeClass("selected");
                $.ajax({
                    url: root + "/api/user?action=listGroups",
                    // JSON的内容:
                    // [{"gid":"...","name":...}, ...]
                    type: "GET",
                    success: (data)=>{
                        var json = JSON.parse(data);
                        $("#content").empty();
                        for(var group of json)
                            addRow(group);
                    }
                });
            }
            
            function addRow(group){
                var tr = $("<tr>");
                tr.attr("gid", group["gid"]);
                tr.attr("name", group["name"]);
                
                $("<td>").text(group["name"]).appendTo(tr);

                var userLink = $("<a>");
                userLink.attr("href", "/usersadmin?gid=" + group["gid"]);
                userLink.text("查看用户...");
                $("<td>").append(userLink).appendTo(tr);
                
                var projectLink = $("<a>");
                projectLink.attr("href", "/projectsadmin?gid=" + group["gid"]);
                projectLink.text("查看项目...");
                $("<td>").append(projectLink).appendTo(tr);
                
                $("#content").append(tr);
                
                tr.click(function(){
                    selected = $(this).attr("gid");
                    $(".selected").removeClass("selected");
                    $(this).addClass("selected");
                });
                
                tr.hover(function(){
                        $(this).addClass("hover");
                    }, 
                    function(){
                        $(this).removeClass("hover");
                    }
                );
            }
            
            $(()=>{
                init();
                $("button").button();
                
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
                    selected = undefined;
                    $(".selected").removeClass("selected");
                    $("#useRegex").prop("checked", false)
                    $("#content").children().show();
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
                                init();
                            else
                                alert(data);
                        }
                    });
                });
                
                $("#removeGroup").click(()=>{
                    if(!selected){
                        alert("未选择分组");
                        return;
                    }
                    if(!confirm("确定删除分组?"))
                        return;
                    $.ajax({
                        url: root + "/api/admin?action=removeGroup&gid=" + selected,
                        type: "POST",
                        success: (data)=>{
                            if(data == "OK")
                                init();
                        }
                    });
                });
            });
            
            function chainFilter(filterFunc){
                selected = undefined;
                $(".selected").removeClass("selected");
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

        <h1>分组列表</h1>
        <p>
            <button onclick="window.location.reload()">
                <span class="ui-icon ui-icon-arrowrefresh-1-s"></span>刷新
            </button>
        </p>
        <p>
            筛选分组:&nbsp;<input type="text" id="filterText" class="text ui-widget-content ui-corner-all" />
            <input type="checkbox" id="useRegex"/>正则表达式
            <button id="doTextFilter" class="btn-primary">确定</button>
            <button id="resetFilter">重置</button>
        </p>
        <p>
            操作:
            <button id="createGroup">
                <span class="ui-icon ui-icon-plusthick"></span>新建分组
            </button>
            <button id="removeGroup">
                <span class="ui-icon ui-icon-minusthick"></span>删除分组
            </button>
        </p>
        <table class="ui-widget ui-widget-content ui-corner-all" style="text-align: center; width: 80%;">
            <thead>
                <tr class="ui-widget-header">
                    <th>分组</th>
                    <th>用户</th>
                    <th>项目</th>
                </tr>
            </thead>
            <tbody id="content"></tbody>
        </table>
		<p><button onclick="window.location.replace('/');">返回AppInventor</button></p>
    </body>
</html>