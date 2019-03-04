package com.google.appinventor.server;

import com.google.appinventor.server.storage.StorageIo;
import com.google.appinventor.server.storage.StorageIoInstanceHolder;
import com.google.appinventor.server.util.PasswordHash;
import com.google.appinventor.shared.rpc.project.UserProject;
import com.google.appinventor.shared.rpc.user.User;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Iterator;
import java.util.List;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.json.JSONArray;
import org.json.JSONObject;

public class UserServlet extends HttpServlet
{
    private final StorageIo storageIo = StorageIoInstanceHolder.INSTANCE;

    public void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException
    {
        resp.addHeader("Access-Control-Allow-Origin", "*");
        resp.setContentType("text/html; charset=utf-8");
        PrintWriter out = resp.getWriter();

        String action = req.getParameter("action");
        if (action == null)
            action = "";
        long pid; switch (action) {
        case "listGroups":
            JSONArray json = new JSONArray();
            for (Iterator localIterator1 = this.storageIo.listGroups().iterator(); localIterator1.hasNext();) { long gid = ((Long)localIterator1.next()).longValue();
                JSONObject obj = new JSONObject();
                obj.put("gid", gid);
                obj.put("name", this.storageIo.getGroupName(gid));
                json.put(obj);
            }
            out.println(json);
            break;

        case "listGroupUsers":
            long gid = Long.parseLong(req.getParameter("gid"));
            json = new JSONArray();
            for (String uid : this.storageIo.getGroupUsers(gid))
                json.put(getUserInfoJSON(uid));
            out.println(json);
            break;

        case "openProject":
            String uid = req.getParameter("uid");
            if (isNullOrEmpty(uid)) {
                out.print("账号不能为空");
                return;
            }
            User user = this.storageIo.getUser(uid);
            pid = 0L;
            String pname; Iterator localIterator3; if (isNullOrEmpty(req.getParameter("pid"))) {
            pname = req.getParameter("pname");
            if (isNullOrEmpty(pname)) {
                out.print("项目名不能为空");
                return;
            }
            for (localIterator3 = this.storageIo.getProjects(uid).iterator(); localIterator3.hasNext();) { long p = ((Long)localIterator3.next()).longValue();
                UserProject project = this.storageIo.getUserProject(uid, p);
                if (pname.equals(project.getProjectName())) {
                    pid = p;
                    break;
                }
            }
        }
        else {
            pid = Long.parseLong(req.getParameter("pid")); }
            if (this.storageIo.getUserProject(uid, pid) == null) {
                out.print("项目不存在");
                return;
            }

            String encodedSettings = this.storageIo.loadSettings(uid);
            if (isNullOrEmpty(encodedSettings)) {
                encodedSettings = "{\"GeneralSettings\":{\"CurrentProjectId\":\"0\",\"DisabledUserUrl\":\"\",\"TemplateUrls\":\"\"},\"SimpleSettings\":{},\"SplashSettings\":{\"DeclinedSurvey\":\"\",\"ShowSurvey\":\"0\",\"SplashVersion\":\"0\"},\"BlocksSettings\":{\"Grid\":\"false\",\"Snap\":\"false\"}}";
            }
            JSONObject obj = new JSONObject(encodedSettings);
            JSONObject generalSettings = obj.getJSONObject("GeneralSettings");
            if (generalSettings == null)
                generalSettings = new JSONObject();
            generalSettings.put("CurrentProjectId", String.valueOf(pid));
            obj.put("GeneralSettings", generalSettings);

            this.storageIo.storeSettings(uid, obj.toString());
            resp.sendRedirect("/");
            break;

        default:
            uid = req.getParameter("uid");
            if (!isNullOrEmpty(uid)) {
                out.println(getUserInfoJSON(uid));
            } else {
                json = new JSONArray();
                for (String _uid : this.storageIo.listUsers())
                    json.put(getUserInfoJSON(_uid));
                out.println(json);
            }
            break;
    }
    }

    public void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException
    {
        resp.addHeader("Access-Control-Allow-Origin", "*");
        resp.setContentType("text/html; charset=utf-8");
        PrintWriter out = resp.getWriter();

        String action = req.getParameter("action");
        if (action == null)
            action = "";
        switch (action) {
            case "register":
                String email = req.getParameter("email");
                String name = req.getParameter("name");
                String password = req.getParameter("password");
                if (isNullOrEmpty(email)) {
                    out.print("账号不能为空");
                    return;
                }
                if (isNullOrEmpty(password)) {
                    out.print("密码不能为空");
                    return;
                }

                User user = this.storageIo.getUserFromEmail(email);
                String hash = user.getPassword();
                if ((hash == null) || (hash.equals(""))) {
                    String hashedPassword = "";
                    try {
                        hashedPassword = PasswordHash.createHash(password);
                    } catch (Exception e) {
                        resp.sendError(500, e.toString());
                        return;
                    }
                    this.storageIo.setUserPassword(user.getUserId(), hashedPassword);
                    if (!isNullOrEmpty(name))
                        this.storageIo.setUserName(user.getUserId(), name);
                    out.print("OK");
                }
                else {
                    out.print("此账号已被注册"); }
                break;

            case "modify":
                String uid = req.getParameter("uid");
                name = req.getParameter("name");
                String oldPassword = req.getParameter("old");
                String newPassword = req.getParameter("new");
                if (isNullOrEmpty(uid)) {
                    out.print("账号不能为空");
                    return;
                }
                if (isNullOrEmpty(name)) {
                    out.print("显示名称不能为空");
                    return;
                }
                if (isNullOrEmpty(oldPassword)) {
                    out.print("旧密码不能为空");
                    return;
                }
                if (newPassword == null) {
                    newPassword = "";
                }
                user = this.storageIo.getUser(uid);
                hash = user.getPassword();
                if ((hash == null) || (hash.equals(""))) {
                    if (newPassword.equals("")) {
                        newPassword = "123456";
                    }
                    String hashedPassword = "";
                    try {
                        hashedPassword = PasswordHash.createHash(newPassword);
                    } catch (Exception e) {
                        resp.sendError(500, e.toString());
                    }
                    this.storageIo.setUserName(uid, name);
                    this.storageIo.setUserPassword(uid, hashedPassword);
                    out.print("OK");
                } else {
                    boolean validLogin = false;
                    try {
                        validLogin = PasswordHash.validatePassword(oldPassword, hash);
                    } catch (Exception e) {
                        resp.sendError(500, e.toString());
                        return;
                    }
                    if (validLogin) {
                        if (!newPassword.equals("")) {
                            String hashedPassword = "";
                            try {
                                hashedPassword = PasswordHash.createHash(newPassword);
                            } catch (Exception e) {
                                resp.sendError(500, e.toString());
                                return;
                            }
                            this.storageIo.setUserPassword(uid, hashedPassword);
                        }
                        this.storageIo.setUserName(uid, name);
                        out.print("OK");
                    } else {
                        out.print("旧密码错误");
                    } }
                break;
        }
    }

    private JSONObject getUserInfoJSON(String uid)
    {
        User user = this.storageIo.getUser(uid);

        JSONObject json = new JSONObject();
        json.put("uid", uid);
        json.put("email", user.getUserEmail());
        json.put("name", user.getUserName());
        json.put("lastVisited", this.storageIo.getUserLastVisited(uid));

        JSONArray groups = new JSONArray();
        for (Iterator localIterator = this.storageIo.getUserGroups(uid).iterator(); localIterator.hasNext();) { long gid = ((Long)localIterator.next()).longValue();
            groups.put(gid); }
        json.put("groups", groups);

        return json;
    }

    private static boolean isNullOrEmpty(String str) {
        return (str == null) || (str.equals(""));
    }
}