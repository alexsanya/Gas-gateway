import statusController from '../controllers/status.controller.js';

const status = {
  method: 'GET',
  url: '/status',
  schema: {
    response: {
      200: {
        type: 'object',
        properties: {
          isFree: { type: 'boolean' },
          lastTransaction: { type: 'string' }
        }
      },
    },
  },
  handler: async (request, reply) => {
    return statusController.getStatus();
  }
}

export default async function StatusRoute(fastify) {
  fastify.route(status);
}

