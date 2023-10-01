import exchangeController from "../controllers/exchange.controller.js";

const exchange = {
  method: 'POST',
  url: '/exchange',
  schema: {
    body: {
      type: 'object',
      properties: {
        wallet: { type: 'string'},
        token: { type: 'string'},
        value: { type: 'string'},
        deadline: { type: 'string'},
        signature: { type: 'string' }
      },
      required: ['wallet', 'token', 'value', 'deadline', 'signature']
    },
    response: {
      200: {
        type: 'object',
        properties: {
          transaction: { type: 'string' }
        }
      },
      400: {
        type: 'object',
        properties: {
          error: { type: 'string' }
        }
      }
    }
  },
  // this function is executed for every request before the handler is executed
  preHandler: async (request, reply) => {
    try {
      await exchangeController.validateInput(request.body);
    } catch (error) {
      return reply.code(400).send({ error: error.message });
    }
  },
  handler: async (request, reply) => {
    return exchangeController.exchange(request.body);
  }
}

export default async function ExchangeRoute(fastify) {
  fastify.route(exchange);
}
