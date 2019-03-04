package com.google.appinventor.server;

import com.google.appinventor.server.storage.StorageIo;
import com.google.appinventor.server.storage.StorageIoInstanceHolder;
import com.google.appinventor.shared.rpc.project.ProjectSourceZip;
import com.google.appinventor.shared.rpc.project.RawFile;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.LinkedList;
import java.util.List;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.http.HttpEntity;
import org.apache.http.HttpHost;
import org.apache.http.HttpResponse;
import org.apache.http.StatusLine;
import org.apache.http.client.CookieStore;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.cookie.Cookie;
import org.apache.http.entity.mime.MultipartEntityBuilder;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONObject;

public class RemoteUploadServlet
        extends HttpServlet
{
    private final StorageIo storageIo = StorageIoInstanceHolder.INSTANCE;
    private final FileExporter fileExporter = new FileExporterImpl();

    protected void service(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.addHeader("Access-Control-Allow-Origin", "*");
        resp.setContentType("text/html; charset=utf-8");
        PrintWriter out = resp.getWriter();

        String action = req.getParameter("action");
        if (action == null)
            action = "";
        switch (action) {
            case "testLogin":
                String hostname = req.getParameter("host");
                int port = 80;
                if (req.getParameter("port") != null)
                    port = Integer.parseInt(req.getParameter("port"));
                String username = req.getParameter("username");
                String password = req.getParameter("password");
                if ((isNullOrEmpty(hostname)) || (isNullOrEmpty(username)) || (isNullOrEmpty(password))) {
                    out.print("NO");
                    return;
                }

                boolean success = false;
                CookieStore cookiestore = new BasicCookieStore();
                try { CloseableHttpClient client = HttpClientBuilder.create().setDefaultCookieStore(cookiestore).build();Throwable localThrowable3 = null;
                    try { HttpHost host = new HttpHost(hostname, port);
                        HttpPost postReq = new HttpPost("/login");

                        List<BasicNameValuePair> params = new LinkedList();
                        params.add(new BasicNameValuePair("email", username));
                        params.add(new BasicNameValuePair("password", password));
                        postReq.setEntity(new UrlEncodedFormEntity(params));

                        client.execute(host, postReq);
                        for (Cookie c : cookiestore.getCookies()) {
                            if (c.getName().equals("AppInventor")) {
                                out.print(c.getValue());
                                success = true;
                                break;
                            }
                        }
                    }
                    catch (Throwable localThrowable1)
                    {
                        localThrowable3 = localThrowable1;throw localThrowable1;
                    }
                    finally
                    {
                        if (client != null) if (localThrowable3 != null) try { client.close(); } catch (Throwable localThrowable2) { localThrowable3.addSuppressed(localThrowable2); } else client.close();
                    } } catch (Exception e) { e.printStackTrace();
                }

                if (!success) {
                    out.print("NO");
                }
                break;
            default:
                hostname = req.getParameter("host");
                port = 80;
                if (req.getParameter("port") != null)
                    port = Integer.parseInt(req.getParameter("port"));
                String cookie = req.getParameter("cookie");
                String uid = req.getParameter("uid");
                long pid = Long.parseLong(req.getParameter("pid"));
                String name = req.getParameter("name");
                if ((isNullOrEmpty(hostname)) || (isNullOrEmpty(cookie)) || (isNullOrEmpty(uid))) {
                    out.print("NO");
                    return;
                }
                if (isNullOrEmpty(name)) {
                    name = this.storageIo.getProjectName(uid, pid);
                }
                success = false;
                try {
                    ProjectSourceZip zipFile = this.fileExporter.exportProjectSourceZip(uid, pid, false, false, null, false, false, false, false);
                    RawFile srcFile = zipFile.getRawFile();
                    byte[] content = srcFile.getContent();

                    CloseableHttpClient client = HttpClientBuilder.create().build();
                    HttpHost host = new HttpHost(hostname, port);
                    HttpPost postReq = new HttpPost("/ode/upload/project/" + name);
                    postReq.setHeader("Cookie", "AppInventor=" + cookie);
                    HttpEntity entity = MultipartEntityBuilder.create().addBinaryBody("uploadProjectArchive", content).build();
                    postReq.setEntity(entity);

                    HttpResponse postResp = client.execute(host, postReq);
                    success = postResp.getStatusLine().getStatusCode() == 200;
                    client.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }

                JSONObject json = new JSONObject();
                json.put("status", success ? "OK" : "NO");
                json.put("name", name);
                out.print(json);
                break;
        }
    }

    private boolean isNullOrEmpty(String s)
    {
        return (s == null) || (s.equals(""));
    }
}