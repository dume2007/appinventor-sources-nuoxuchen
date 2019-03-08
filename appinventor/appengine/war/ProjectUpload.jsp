<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String uid = request.getParameter("uid");
%>
<!DOCTYPE html>
<html>

<head>

  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <title>上传到官方服务器</title>

  <link href="bootstrap-4.2.1-dist/vendor/bootstrap/css/bootstrap.min.css" rel="stylesheet">
  <link href="bootstrap-4.2.1-dist/vendor/fontawesome-free/css/all.min.css" rel="stylesheet">
  <link href="bootstrap-4.2.1-dist/css/resume.min.css" rel="stylesheet">
  <script src="bootstrap-4.2.1-dist/vendor/jquery/jquery.min.js"></script>
  <script src="bootstrap-4.2.1-dist/vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

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
<body id="page-top">
  <nav class="navbar navbar-expand-lg navbar-dark bg-dark" id="sideNav" >
    <a class="navbar-brand js-scroll-trigger" href="#page-top">

        <img class="img-fluid img-profile rounded-circle mx-auto mb-3" src="images/profile.png" alt="">
      </span>
    </a>
	
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarSupportedContent">
		<ul class="navbar-nav">
		<li class="nav-item">
			<div class="input-group mb-3">
				<div class="input-group-prepend">
					<span class="input-group-text">服务器</span>
				</div>
				<input type="text" class="form-control" placeholder="请输入地址" id="server" name="server" value="app.gzjkw.net">
				<input  style="width:38px"  id="port" type="number" value="80" min="0" max="32767" />
			</div>
		</li>
		<li class="nav-item">
			<div class="input-group mb-3">
				<div class="input-group-prepend">
					<span class="input-group-text">账号</span>
				</div>
				<input type="text" class="form-control" placeholder="请输入账号" id="username" name="username">
			</div>
		</li>
		<li class="nav-item">
			<div class="input-group mb-3">
				<div class="input-group-prepend">
					<span class="input-group-text">密码</span>
				</div>
				<input type="password" class="form-control" placeholder="请输入密码" id="password" name="password">
			</div>
		</li>

		<li class="nav-item">
			<div class="input-group mb-3">
				<div class="input-group-prepend">
				</div>
					<button id="testLogin" type="button" class="btn btn-primary btn-block">登录</button>	
			</div>
		</li>
		<li class="nav-item">
				<span id="loginStatus"></span></p>
		</li>

		</ul>
    </div>
  </nav>
  <div class="container-fluid p-0">

    <section class="resume-section p-3 p-lg-5 d-flex align-items-start" id="about">
      <div class="w-100">
        <h2 class="mb-0">本地项目</h2>
        <div class="subheading mb-5">当前用户所有的项目
        </div>
        <p class="lead mb-5">
		<table id="localProjects" width="100%" border="1" style="text-align: center;">
            <tr>
                <th>选择(<a href="#" id="selectAll">全部选中</a>/<a href="#" id="deselectAll">清除选择</a>)</th>
                <th>项目名</th>
                <th>上传项目名</th>
                <th>修改时间</th>
            </tr>
        </table>
        <hr/>		


		<button id="submit" class="btn btn-outline-success">同步</button>
        
        <hr/>
        <div id="uploadLog"></div>
        <p><button class="btn btn-primary" onclick="window.location.replace('/');">返回AppInventor</button></p>
		</p>

      </div>
    </section>

  </div>

</body>

</html>
