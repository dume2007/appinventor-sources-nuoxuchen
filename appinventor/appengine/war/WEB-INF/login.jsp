<%@page import="javax.servlet.http.HttpServletRequest"%>
<%@page import="com.google.appinventor.server.util.UriBuilder"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!doctype html>
<%
   String error = request.getParameter("error");
   String useGoogleLabel = (String) request.getAttribute("useGoogleLabel");
   String locale = request.getParameter("locale");
   String redirect = request.getParameter("redirect");
   String repo = (String) request.getAttribute("repo");
   String galleryId = (String) request.getAttribute("galleryId");
   if (locale == null) {
       locale = "zh_CN";
   }

%>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta HTTP-EQUIV="pragma" CONTENT="no-cache"/>
    <meta HTTP-EQUIV="Cache-Control" CONTENT="no-cache, must-revalidate"/>
    <meta HTTP-EQUIV="expires" CONTENT="0"/>
    <link rel="stylesheet"href="/bootstrap-4.2.1-dist/css/bootstrap.min.css">
    <script src="/bootstrap-4.2.1-dist/js/jquery-3.3.1.min.js"></script>
    <script src="/bootstrap-4.2.1-dist/js/bootstrap.min.js"></script>

    <title>App Inventor2 测试版</title>
        <style>
            #box{
                position: absolute;
                background: #ffffff;
                box-shadow: 0 2px 4px 0 rgba(0,0,0,0.50);
                border-radius: 10px;
                width: 500px;
                height: 540px;
                top: 0;
                bottom: 0;
                left: 0;
                right: 0;
                text-align: center;
                margin: auto;
            }
            #box2{
                position: fixed;
                top: 43%;
                height: 100px;
                width: 350px;
                font-size: 14px;
                margin-left: 80px;
                text-align: center;
                background-color: rgb(255, 255, 255);
                padding: 20px;

            }
            #box3{
                position: absolute;
                top: 26%;
                height: 23px;
                width: 400px;
                font-size: 0px;
                margin: 50px;
                text-align: center;
                background-color: rgb(255, 255, 255);
                padding: 0px;

            }
        </style>
  </head>
<body style="background-image: url(/images/squairy_light.png);">
			<div class="modal fade" id="myModal">
			
				<div class="modal-dialog">
					<div class="modal-content">

					<div class="modal-header">
					<h4 class="modal-title">注册新账号</h4>
					<button type="button" class="close" data-dismiss="modal">&times;</button>
				</div>

				<div class="modal-body">
				    <form>
						<div class="form-group">
							<label>账号</label>
							<input type="email" class="form-control" id ="Remail"name="email" placeholder="请输入账号">
						</div>
						<div class="form-group">
							<label>密码</label>
							<input type="password" class="form-control" id ="Rpassword" name="password" placeholder="请输入密码">
						</div>
					</form>
				</div>
   
				<!-- 模态框底部 -->
				<div class="modal-footer">
				<button id = "register" type="register" class="btn btn-success" >注册</button>
				<button type="button" class="btn btn-secondary" data-dismiss="modal">关闭</button>
				</div>
   
				</div>
				</div>
			</div>
		<script>
		<%
			String  realPath  =  "\"" + "http://"  +  request.getServerName()  +  ":"  +  request.getServerPort() +"\"" ;  
			System.out.println(realPath);
		%>
            $(()=>{
                const root = 
				<%=realPath%>
                $("#register").click(()=>{
                    $.ajax({
                        type: "POST",
                        url: root + "/api/user/?action=register",
                        data: encodeURI("email=" + $("#Remail").val() + "&password=" + $("#Rpassword").val()),
                        success: (data)=>{
                            if(data == "OK"){
                                alert("注册成功!");
                                window.location.replace("/");
                            }
                            else
                                alert(data);
                        }
                    });
                });
            });
        </script>
<form method=POST action="/login">
    <div id="box">
        <p></p>
        <img src="/images/codi_long.png"  height="100" width="420"></img>
        <p></p>
        <h1 class="text-center">${pleaselogin}</h1>

        <div id="box3">

                    <% if (error != null) {
                        out.println("<strong><h5 class=\"text-center\"><font color=red>" + error + "</font></strong></h5>"); }
                    %>

        </div>
        <div id="box2">
            <div class="input-group mb-3">
                <div class="input-group-prepend">
                    <span class="input-group-text">${emailAddressLabel}</span>
                </div>
                <input type="text" class="form-control" placeholder="请输入你的账号" id="email" name="email">
            </div>

            <div class="input-group mb-3">
                <div class="input-group-prepend">
                    <span class="input-group-text">${passwordLabel}</span>
                </div>
                <input type="password" class="form-control" placeholder="请输入你的密码" id="password" name="password">
            </div>

            <button type="Submit" class="btn btn-primary btn-block" >${login}</button>
            <P></P>
            <button type="button" class="btn btn-outline-success btn-block" data-toggle="modal" data-target="#myModal">${register}</button>

  

            <p></p>

<%    if (useGoogleLabel != null && useGoogleLabel.equals("true")) { %>
<p><a href="<%= new UriBuilder("/login/google")
                              .add("locale", locale)
                              .add("repo", repo)
                              .add("galleryId", galleryId)
                              .add("redirect", redirect).build() %>" style="text-decoration:none;">Click Here to use your Google Account to login</a></p>
<%    } %>
            <a href="<%= new UriBuilder("/login")
                           .add("locale", "zh_CN")
                           .add("repo", repo)
                           .add("galleryId", galleryId)
                           .add("redirect", redirect).build() %>"  style="text-decoration:none;" >中文</a>&nbsp;
            <a href="<%= new UriBuilder("/login")
                   .add("locale", "en")
                   .add("repo", repo)
                   .add("galleryId", galleryId)
                   .add("redirect", redirect).build() %>"  style="text-decoration:none;" >English</a>
        </div>


    </div>
<p></p>
<% if (locale != null && !locale.equals("")) {
   %>
<input type=hidden name=locale value="<%= locale %>">
<% }
   if (repo != null && !repo.equals("")) {
   %>
<input type=hidden name=repo value="<%= repo %>">
<% }
   if (galleryId != null && !galleryId.equals("")) {
   %>
<input type=hidden name=galleryId value="<%= galleryId %>">
<% } %>
<% if (redirect != null && !redirect.equals("")) {
   %>
<input type=hidden name=redirect value="<%= redirect %>">
<% } %>
<p>
</p>
</form>

<p></p>
</body>
</html>

