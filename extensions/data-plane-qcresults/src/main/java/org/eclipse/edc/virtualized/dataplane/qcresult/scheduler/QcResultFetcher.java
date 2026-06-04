package org.eclipse.edc.virtualized.dataplane.qcresult.scheduler;

import org.eclipse.edc.virtualized.dataplane.qcresult.model.QcResult;

import java.util.List;

public interface QcResultFetcher {
    List<QcResult> fetch();
}