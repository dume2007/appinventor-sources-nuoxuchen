package com.google.appinventor.server;

import com.google.appinventor.server.storage.StorageIo;
import com.google.appinventor.server.storage.StorageIoInstanceHolder;
import com.google.appinventor.server.util.PasswordHash;
import com.google.appinventor.shared.rpc.user.User;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;


import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.json.JSONArray;
import org.json.JSONObject;
public class AdminServlet
        extends HttpServlet
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
        switch (action) {
            case "exportUsersCSV":

            resp.setHeader("content-disposition", "attachment; filename=users.csv");
            resp.setContentType("text/plain;charset=utf-8");
            for (String uid : this.storageIo.listUsers()) {
                User user = this.storageIo.getUser(uid);
                out.printf("%s,%s,%s\n", new Object[]{user.getUserEmail(), user.getUserName(), user.getPassword()});
            }
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
            case "importUsersCSV":
                String content = req.getParameter("content");
                if (isNullOrEmpty(content)) {
                    return;
                }
                int count = 0;
                for (String row : content.split("\\n")) {
                    String[] parts = row.split(",");
                    String email = parts[0];
                    String name = parts.length > 1 ? parts[1] : email;
                    String password = parts.length > 2 ? parts[2] : "123456";

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
                        this.storageIo.setUserName(user.getUserId(), name);
                        count++;
                    }
                }
                out.print("成功导入" + count + "条记录");
                break;

            case "passwordReset":
                String uid = req.getParameter("uid");
                String password = req.getParameter("password");
                if (isNullOrEmpty(uid))
                    return;
                if (isNullOrEmpty(password)) {
                    return;
                }
                User user = this.storageIo.getUser(uid);
                String hashedPassword = "";
                try {
                    hashedPassword = PasswordHash.createHash(password);
                } catch (Exception e) {
                    resp.sendError(500, ((Exception)e).toString());
                    return;
                }
                this.storageIo.setUserPassword(uid, hashedPassword);
                out.print("OK");
                break;

            case "removeUsers":
                String usersJSON = req.getParameter("users");
                if (isNullOrEmpty(usersJSON)) {
                    return;
                }
                JSONArray users = new JSONArray(usersJSON);
                for (int i = 0; i < users.length(); i++) {
                    uid = users.getString(i);
                    for (Iterator<Long> e = this.storageIo.getProjects(uid).iterator(); ((Iterator)e).hasNext();) { long pid = ((Long)((Iterator)e).next()).longValue();
                        this.storageIo.deleteProject(uid, pid); }
                    this.storageIo.removeUser(uid);
                }
                out.print("OK");
                break;

            case "deleteProjects":
                String projectsJSON = req.getParameter("projects");
                if (isNullOrEmpty(projectsJSON)) {
                    return;
                }
                JSONArray projects = new JSONArray(projectsJSON);
                for (int i = 0; i < projects.length(); i++) {
                    JSONObject project = projects.getJSONObject(i);
                    this.storageIo.deleteProject(project.getString("uid"), project.getLong("pid"));
                }
                out.print("OK");
                break;

            case "createGroup":
                String name = req.getParameter("name");
                if (isNullOrEmpty(name))
                    return;
                if (this.storageIo.findGroupByName(name) != 0L) {
                    out.print("存在同名分组");
                    return;
                }
                this.storageIo.createGroup(name);
                out.print("OK");
                break;

            case "removeGroup":
                long gid = Long.parseLong(req.getParameter("gid"));
                this.storageIo.removeGroup(gid);
                out.print("OK");
                break;

            case "addUsersToGroup":
                gid = Long.parseLong(req.getParameter("gid"));
                usersJSON = req.getParameter("users");
                if (isNullOrEmpty(usersJSON)) {
                    return;
                }
                users = new JSONArray(usersJSON);
                Object list = new ArrayList();
                for (int i = 0; i < users.length(); i++)
                    ((ArrayList)list).add(users.getString(i));
                this.storageIo.addUsersToGroup(gid, (List)list);
                out.print("OK");
                break;

            case "removeUsersFromGroup":
                gid = Long.parseLong(req.getParameter("gid"));
                usersJSON = req.getParameter("users");
                if (isNullOrEmpty(usersJSON)) {
                    return;
                }
                users = new JSONArray(usersJSON);
                list = new ArrayList();
                for (int i = 0; i < users.length(); i++)
                    ((ArrayList)list).add(users.getString(i));
                this.storageIo.removeUsersFromGroup(gid, (List)list);
                out.print("OK");
                break;
        }
    }

    private static boolean isNullOrEmpty(String str)
    {
        return (str == null) || (str.equals(""));
    }
}