const express = require('express');
const TicketController = require('../controllers/ticketController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');
const { validate, schemas } = require('../middleware/validation');

const router = express.Router();

router.use(authMiddleware);

router.post('/', validate(schemas.createTicket), TicketController.create);
router.get('/', TicketController.list);
router.get('/stats', TicketController.getStats);
router.get('/:ticketId', TicketController.getDetail);
router.get('/:ticketId/history', TicketController.getHistory);
router.patch('/:ticketId', validate(schemas.updateTicket), TicketController.update);
router.delete('/:ticketId', TicketController.delete);

module.exports = router;
