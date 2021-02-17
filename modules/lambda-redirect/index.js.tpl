exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    if (request.headers.host[0].value !== '${domain_name}') {
        return {
            status: '301',
            statusDescription: 'Moved Permanently',
            headers: {
                location: [{
                    key: 'Location',
                    value: `https://${domain_name}$${request.uri}`
                }]
            }
        };
    }
    return request;
};
