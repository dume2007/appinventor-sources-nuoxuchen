<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String uid = request.getParameter("uid");
%>
<!doctype html>
<html>
    <head>
        <meta charset="utf8">
        <script src="jquery/jquery-3.2.1.min.js"></script>
        <title>上传项目文件至远程服务器</title>
    </head>
    <script>
        $(()=>{
            var selectedPIDs = new Set();
            var ucookie = "";
            
            var req = $.get("/api/file?action=listUserProjects&uid=<%=uid%>");
            $.when(req).done((data)=>{
                var projects = JSON.parse(data);
                for(var p of projects){
                    var tr = $("<tr>");
                    tr.attr("pid", p.pid);
                    var cb = $('<input type="checkbox">');
                    cb.change(function(){
                        var _tr = $(this).closest("tr");
                        if($(this).prop("checked"))
                            selectedPIDs.add(_tr.attr("pid"));
                        else
                            selectedPIDs.delete(_tr.attr("pid"));
                    });
                    $("<td>").append(cb).appendTo(tr);
                    $("<td>").text(p.name).appendTo(tr);
                    var customProjectName = $('<input type="text">');
                    customProjectName.val(p.name);
                    $("<td>").append(customProjectName).appendTo(tr);
                    $("<td>").text(new Date(p.dateModified).toLocaleString()).appendTo(tr);
                    
                    $("#localProjects").append(tr);
                }
            });
            
            $("#testLogin").click(()=>{
                var server = $("#server").val();
                var port = $("#port").val() || 80;
                var username = $("#username").val();
                var password = $("#password").val();
                if(!server){
                    alert("服务器地址不能为空");
                    return;
                }
                if(!username){
                    alert("用户名不能为空");
                    return;
                }
                if(!password){
                    alert("密码不能为空");
                    return;
                }
                
                var url = "/api/remoteUpload?action=testLogin";
                url += "&host=" + encodeURIComponent(server);
                url += "&port=" + port;
                url += "&username=" + encodeURIComponent(username);
                url += "&password=" + encodeURIComponent(password);
                var req = $.ajax(url);
                $.when(req).done((data)=>{
                    if(data == "NO"){
                        $("#loginStatus").css("color", "red").text("登录失败");
                        alert("登录失败");
                    }
                    else{
                        $("#loginStatus").css("color", "green").text("登录成功");
                        ucookie = data;
                        alert("登录成功");
                    }
                });
            });
            
            $("#selectAll").click(()=>{
                var cb = $("#localProjects input[type='checkbox']");
                cb.prop("checked", true);
                cb.trigger("change");
            });
            
            $("#deselectAll").click(()=>{
                var cb = $("#localProjects input[type='checkbox']");
                cb.prop("checked", false);
                cb.trigger("change");
            });
            
            $("#submit").click(()=>{
                var server = $("#server").val();
                if(!server){
                    alert("服务器地址不能为空");
                    return;
                }
                var port = $("#port").val() || 80;
                if(!ucookie){
                    alert("请先登录");
                    return;
                }
                if(selectedPIDs.size == 0){
                    alert("请选择要上传的项目");
                    return;
                }
                if(!confirm("注意: 远程服务器上的同名项目可能会被覆盖!"))
                    return;
                
                var successCnt = 0;
                var length = selectedPIDs.length;
                for(var pid of selectedPIDs){
                    var url = "/api/remoteUpload";
                    url += "?host=" +encodeURIComponent(server);
                    url += "&port=" + port;
                    url += "&cookie=" + encodeURIComponent(ucookie);
                    url += "&uid=<%=uid%>&pid=" + pid;
                    url += "&name=" + $("tr[pid=" + pid + "] :text").val();
                    var req = $.ajax(url);
                    $.when(req).done((data)=>{
                        var json = JSON.parse(data);
                        $("<p>").text("项目" + json.name + "上传" + ((json.status == "OK") ? "成功" : "失败")).appendTo($("#uploadLog"));
                        if(json.status == "OK"){
                            successCnt++;
                            if(successCnt == selectedPIDs.size)
                                alert("所有项目上传成功");
                        }
                    });
                }
            });
        });
    </script>
    <body>
        <h1>上传项目文件至远程服务器</h1>
        <hr/>
        
        <div id="pwLogin">
            <h2>登录信息</h2>
            <p>
            服务器地址: <input id="server" type="text" value="app.gzjkw.net"/>
            端口号: <input id="port" type="number" value="80" min="0" max="32767" />
            </p>
            <p>账号: <input id="username" type="text"/></p>
            <p>密码: <input id="password" type="password"/></p>
            <p>测试登录: <button id="testLogin">登录</button> <span id="loginStatus"></span></p>
        </div>
        <div id="nwLogin">
        </div>
        
        <hr/>
        <h2>本地项目</h2>
        <table id="localProjects" width="80%" border="1" style="text-align: center;">
            <tr>
                <th>选择(<a href="#" id="selectAll">全部选中</a>/<a href="#" id="deselectAll">清除选择</a>)</th>
                <th>项目名</th>
                <th>上传项目名</th>
                <th>修改时间</th>
            </tr>
        </table>
        <button id="submit">同步</button>
        
        <hr/>
        <div id="uploadLog"></div>
        <p><button onclick="window.location.replace('/');">返回AppInventor</button></p>
    </body>
</html>