package com.google.appinventor.server;

import com.google.appinventor.server.storage.StorageIo;
import com.google.appinventor.shared.rpc.Nonce;
import com.google.appinventor.shared.rpc.admin.AdminUser;
import com.google.appinventor.shared.rpc.project.ProjectSourceZip;
import com.google.appinventor.shared.rpc.project.RawFile;
import com.google.appinventor.shared.rpc.user.User;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Iterator;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.commons.codec.binary.Base64;
import org.json.JSONArray;
import org.json.JSONObject;

public class FileServlet extends javax.servlet.http.HttpServlet
{
    private final StorageIo storageIo = com.google.appinventor.server.storage.StorageIoInstanceHolder.INSTANCE;
    private final FileImporter fileImporter = new FileImporterImpl();
    private final FileExporter fileExporter = new FileExporterImpl();

    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.addHeader("Access-Control-Allow-Origin", "*");
        resp.setContentType("text/html; charset=utf-8");

        String action = req.getParameter("action");
        if (action == null)
            action = "";
        Nonce nonce; switch (action) {
            case "listUserProjects":
                String uid = req.getParameter("uid");
                if (isNullOrEmpty(uid)) {
                    return;
                }
                resp.getWriter().println(getUserProjects(uid));
                break;

            case "listProjectFiles":
                uid = req.getParameter("uid");
                long pid = Long.parseLong(req.getParameter("pid"));
                if (isNullOrEmpty(uid)) {
                    return;
                }
                JSONObject json = new JSONObject();
                json.put("uid", uid);
                json.put("pid", pid);
                json.put("sources", this.storageIo.getProjectSourceFiles(uid, pid));
                json.put("outputs", this.storageIo.getProjectOutputFiles(uid, pid));
                resp.getWriter().println(json);
                break;

            case "exportFile":
                uid = req.getParameter("uid");
                pid = Long.parseLong(req.getParameter("pid"));
                String path = req.getParameter("path");
                if ((isNullOrEmpty(uid)) || (isNullOrEmpty(path))) {
                    return;
                }
                attachDownloadData(resp, exportFile(uid, pid, path));
                break;

            case "exportProject":
                uid = req.getParameter("uid");
                pid = Long.parseLong(req.getParameter("pid"));
                if (isNullOrEmpty(uid)) {
                    return;
                }
                attachDownloadData(resp, exportProject(uid, pid));
                break;

            case "exportAllProjectsForUser":
                uid = req.getParameter("uid");
                if (isNullOrEmpty(uid)) {
                    return;
                }
                attachDownloadData(resp, exportAllProjectsForUser(uid));
                break;

            case "exportAllProjects":
                String usersJSON = req.getParameter("users");
                attachDownloadData(resp, exportAllProjects(usersJSON));
                break;

            case "exportProjectsBatched":
                String projectsJSON = req.getParameter("projects");
                if (isNullOrEmpty(projectsJSON)) {
                    return;
                }
                attachDownloadData(resp, exportProjectsBatched(projectsJSON));
                break;

            case "getSharedProject":
                String nonceValue = req.getParameter("nonce");
                if (isNullOrEmpty(nonceValue)) {
                    return;
                }
                nonce = this.storageIo.getNoncebyValue(nonceValue);
                if (nonce != null) {
                    attachDownloadData(resp, exportProject(nonce.getUserId(), nonce.getProjectId()));
                } else
                    resp.getWriter().print("分享链接已过期或项目不存在");
                break;

            default:
                json = new JSONObject();
                for (String puid : this.storageIo.listUsers())
                    json.put(puid, getUserProjects(puid));
                resp.getWriter().println(json);
                break;
        }
    }

    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException
    {
        resp.addHeader("Access-Control-Allow-Origin", "*");
        resp.setContentType("text/html; charset=utf-8");
        PrintWriter out = resp.getWriter();

        String action = req.getParameter("action");
        if (action == null)
            action = "";
        switch (action) {
            case "importProject":
                String users = req.getParameter("users");
                String name = req.getParameter("name");
                String encodedContent = req.getParameter("content");
                if ((isNullOrEmpty(users)) || (isNullOrEmpty(name)) || (isNullOrEmpty(encodedContent))) {
                    return;
                }
                byte[] content = null;
                try {
                    content = Base64.decodeBase64(encodedContent);
                } catch (Exception e) {
                    e.printStackTrace();
                    resp.sendError(500, e.toString());
                    return;
                }

                JSONArray json = new JSONArray(users);
                for (int i = 0; i < json.length(); i++) {
                    String uid = json.getString(i);
                    String importName = name;
                    for (Iterator localIterator = this.storageIo.getProjects(uid).iterator(); localIterator.hasNext();) { long pid = ((Long)localIterator.next()).longValue();
                        if (this.storageIo.getProjectName(uid, pid).equals(name))
                            importName = importName + "_copy";
                    }
                    try {
                        ByteArrayInputStream bin = new ByteArrayInputStream(content);
                        this.fileImporter.importProject(uid, importName, bin, null);
                    } catch (Exception e) {
                        e.printStackTrace();
                        resp.sendError(500, e.toString());
                        return;
                    }
                }
                out.print("OK");
                break;

            case "shareProject":
                String uid = req.getParameter("uid");
                long pid = Long.parseLong(req.getParameter("pid"));
                if (isNullOrEmpty(uid)) {
                    return;
                }
                name = uid + pid;
                String nonceValue = new String(Base64.encodeBase64(name.getBytes("UTF-8")), "UTF-8");
                this.storageIo.storeNonce(nonceValue, uid, pid);
                out.print(nonceValue);
                break;
        }
    }

    private JSONArray getUserProjects(String uid)
    {
        JSONArray json = new JSONArray();
        for (Iterator localIterator = this.storageIo.getProjects(uid).iterator(); localIterator.hasNext();) { long pid = ((Long)localIterator.next()).longValue();
            JSONObject obj = new JSONObject();
            obj.put("uid", uid);
            obj.put("pid", pid);
            obj.put("name", this.storageIo.getProjectName(uid, pid));
            obj.put("dateCreated", this.storageIo.getProjectDateCreated(uid, pid));
            obj.put("dateModified", this.storageIo.getProjectDateModified(uid, pid));
            json.put(obj);
        }
        return json;
    }

    private RawFile exportFile(String uid, long pid, String path) {
        RawFile file = null;
        try {
            file = this.fileExporter.exportFile(uid, pid, path);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return file;
    }

    private RawFile exportProject(String uid, long pid) {
        RawFile srcFile = null;
        try {
            ProjectSourceZip zipFile = this.fileExporter.exportProjectSourceZip(uid, pid, false, false, null, false, false, false, false);
            srcFile = zipFile.getRawFile();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return srcFile;
    }

    private RawFile exportAllProjectsForUser(String uid) {
        String email = this.storageIo.getUser(uid).getUserEmail();
        RawFile file = null;
        try {
            ProjectSourceZip zipFile = this.fileExporter.exportAllProjectsSourceZip(uid, "all-projects-" + email + ".zip");
            file = zipFile.getRawFile();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return file;
    }

    private RawFile exportAllProjects(String users) {
        List<String> targets = null;
        if (!isNullOrEmpty(users)) {
            targets = new java.util.ArrayList();
            JSONArray json = new JSONArray(users);
            for (int i = 0; i < json.length(); i++) {
                targets.add(json.getString(i));
            }
        }
        ByteArrayOutputStream zipFile = new ByteArrayOutputStream();
        try { ZipOutputStream out = new ZipOutputStream(zipFile);Throwable localThrowable3 = null;
            try { for (AdminUser user : this.storageIo.searchUsers("")) {
                String uid = user.getId();
                if ((targets == null) || (targets.contains(uid)))
                {
                    String email = user.getEmail();
                    for (Iterator<Long> localIterator2 = this.storageIo.getProjects(uid).iterator(); localIterator2.hasNext();) { long pid = ((Long)localIterator2.next()).longValue();
                        RawFile file = exportProject(uid, pid);
                        out.putNextEntry(new ZipEntry(email + "/" + file.getFileName()));
                        out.write(file.getContent());
                        out.closeEntry();
                    }
                }
            }
            }
            catch (Throwable localThrowable5)
            {
                String uid;
                String email;
                Iterator localIterator2;
                localThrowable3 = localThrowable5;throw localThrowable5;

            }
            finally
            {
                if (out != null) if (localThrowable3 != null) try { out.close(); } catch (Throwable localThrowable2) { localThrowable3.addSuppressed(localThrowable2); } else out.close();
            } } catch (Exception e) { e.printStackTrace();
        }
        return new RawFile("all-projects.zip", zipFile.toByteArray());
    }

    private RawFile exportProjectsBatched(String projects) {
        ByteArrayOutputStream zipFile = new ByteArrayOutputStream();
        try { ZipOutputStream out = new ZipOutputStream(zipFile);Throwable localThrowable3 = null;
            try { JSONArray json = new JSONArray(projects);
                for (int i = 0; i < json.length(); i++) {
                    JSONObject obj = json.getJSONObject(i);
                    String uid = obj.getString("uid");
                    long pid = obj.getLong("pid");

                    User user = this.storageIo.getUser(uid);
                    String email = user.getUserEmail();
                    RawFile file = exportProject(uid, pid);
                    out.putNextEntry(new ZipEntry(email + "/" + file.getFileName()));
                    out.write(file.getContent());
                    out.closeEntry();
                }
            }
            catch (Throwable localThrowable1)
            {
                localThrowable3 = localThrowable1;throw localThrowable1;
            }
            finally
            {
                if (out != null) if (localThrowable3 != null) try { out.close(); } catch (Throwable localThrowable2) { localThrowable3.addSuppressed(localThrowable2); } else out.close();
            } } catch (Exception e) { e.printStackTrace();
        }
        return new RawFile("all-projects.zip", zipFile.toByteArray());
    }

    private void attachDownloadData(HttpServletResponse resp, RawFile file) {
        if (file == null) {
            resp.setStatus(404);
            return;
        }

        String fileName = file.getFileName();
        byte[] content = file.getContent();

        resp.setStatus(200);
        resp.setHeader("content-disposition", "attachment; filename=\"" + fileName + "\"");
        resp.setContentType(com.google.appinventor.shared.storage.StorageUtil.getContentTypeForFilePath(fileName));
        resp.setContentLength(content.length);
        try {
            ServletOutputStream out = resp.getOutputStream();Throwable localThrowable3 = null;
            try { out.write(content);
            }
            catch (Throwable localThrowable1)
            {
                localThrowable3 = localThrowable1;throw localThrowable1;
            } finally {
                if (out != null) if (localThrowable3 != null) try { out.close(); } catch (Throwable localThrowable2) { localThrowable3.addSuppressed(localThrowable2); } else out.close();
            } } catch (Exception e) { e.printStackTrace();
        }
    }

    private static boolean isNullOrEmpty(String str) {
        return (str == null) || (str.equals(""));
    }
}
