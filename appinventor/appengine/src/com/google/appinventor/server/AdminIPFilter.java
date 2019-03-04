package com.google.appinventor.server;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletResponse;

public class AdminIPFilter
        implements Filter
{
    public void init(FilterConfig config) {}

    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain)
            throws IOException, ServletException
    {
        String ip = req.getRemoteAddr();
        if (ip.equals("127.0.0.1") || ip.equals("localhost") ) {
            chain.doFilter(req, resp);
        } else {
            ((HttpServletResponse)resp).setStatus(401);
            return;
        }
    }

    public void destroy() {}
}