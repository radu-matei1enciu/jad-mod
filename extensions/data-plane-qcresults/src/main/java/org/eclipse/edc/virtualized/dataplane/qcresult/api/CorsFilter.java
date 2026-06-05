package org.eclipse.edc.virtualized.dataplane.qcresult.api;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;

@Provider
@PreMatching
@Priority(Priorities.AUTHENTICATION - 100)
public class CorsFilter implements ContainerRequestFilter, ContainerResponseFilter {

    private static final String ORIGIN = "http://ui.localhost";

    @Override
    public void filter(ContainerRequestContext req) {
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) {
            req.abortWith(
                    Response.ok()
                            .header("Access-Control-Allow-Origin",  ORIGIN)
                            .header("Access-Control-Allow-Methods", "GET, OPTIONS")
                            .header("Access-Control-Allow-Headers", "Authorization, Content-Type, Accept")
                            .header("Access-Control-Max-Age",       "3600")
                            .build()
            );
        }
    }

    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext res) {
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) {
            return; // headers already set in abortWith()
        }
        res.getHeaders().putSingle("Access-Control-Allow-Origin",  ORIGIN);
        res.getHeaders().putSingle("Access-Control-Allow-Methods", "GET, OPTIONS");
        res.getHeaders().putSingle("Access-Control-Allow-Headers", "Authorization, Content-Type, Accept");
    }
}
