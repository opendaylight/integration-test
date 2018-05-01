NETVIRT_EXCEPTIONS_WHITELIST = [
    'OptimisticLockFailedException',
    'ConflictingModificationAppliedException: Node was created by other transaction',
    'ConflictingModificationAppliedException: Node was deleted by other transaction',
    'org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException',
    'org.opendaylight.controller.md.sal.dom.broker.impl.TransactionCommitFailedExceptionMapper',
    'org.opendaylight.yangtools.util.concurrent.ExceptionMapper.apply',
    'org.opendaylight.mdsal.common.api.MappingCheckedFuture.mapException',
    'org.opendaylight.mdsal.common.api.MappingCheckedFuture.wrapInExecutionException',
    'org.opendaylight.yang.gen.v1.urn.opendaylight.openflow.oxm.rev150225.match.entries.grouping.MatchEntry msgType: 1 oxm_field: 33 experimenterID: null was not found - please verify that all needed deserializers ale loaded correctly', # noqa
    'InterruptedByTimeoutException: null'
]
