import Fastify from 'fastify';
import config from './config.js';
import { getLogger } from './utils/logger.util.js';
import ExchangeRoute from './routes/exchange.route.js';
import StatusRoute from './routes/status.route.js';

const logger = getLogger('server');

const fastify = Fastify({
  logger: true
})

fastify.register(ExchangeRoute);
fastify.register(StatusRoute);

const { PORT } = config;

try {
  await fastify.listen({ port: PORT });
  logger.info(`Server is listening on port ${PORT}`);
} catch (err) {
  fastify.log.error(err)
  process.exit(1)
}
