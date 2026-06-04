package org.eclipse.edc.virtualized.dataplane.qcresult;

import org.eclipse.edc.runtime.metamodel.annotation.Extension;
import org.eclipse.edc.runtime.metamodel.annotation.Provider;
import org.eclipse.edc.spi.system.ServiceExtension;
import org.eclipse.edc.virtualized.dataplane.qcresult.scheduler.QcResultFetcher;
import org.eclipse.edc.virtualized.dataplane.qcresult.scheduler.demo.DemoQcResultFetcher;

import static org.eclipse.edc.virtualized.dataplane.qcresult.QcResultSchedulerExtension.NAME;

@Extension(NAME)
public class QcResultSchedulerExtension implements ServiceExtension {
    public static final String NAME = "QC Result Scheduler Extension";

    @Provider
    public QcResultFetcher qcResultFetcher() {
        return new DemoQcResultFetcher();
    }
}