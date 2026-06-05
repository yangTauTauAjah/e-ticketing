const Joi = require('joi');

const schemas = {
  register: Joi.object({
    email: Joi.string()
      .email()
      .required()
      .messages({
        'string.email': 'Email must be valid',
        'any.required': 'Email is required'
      }),
    username: Joi.string()
      .alphanum()
      .min(3)
      .max(50)
      .required()
      .messages({
        'string.alphanum': 'Username must be alphanumeric',
        'string.min': 'Username must be at least 3 characters',
        'string.max': 'Username cannot exceed 50 characters',
        'any.required': 'Username is required'
      }),
    password: Joi.string()
      .min(8)
      .pattern(/[A-Z]/)
      .pattern(/[a-z]/)
      .pattern(/[0-9]/)
      .pattern(/[!@#$%^&*]/)
      .required()
      .messages({
        'string.min': 'Password must be at least 8 characters',
        'string.pattern.base': 'Password must contain uppercase, lowercase, number, and special character',
        'any.required': 'Password is required'
      }),
    name: Joi.string()
      .max(255)
      .required(),
    phone: Joi.string()
      .pattern(/^[0-9]{10,}$/)
      .optional()
      .messages({
        'string.pattern.base': 'Phone must be at least 10 digits'
      })
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),

  createTicket: Joi.object({
    title: Joi.string().min(5).max(255).required(),
    description: Joi.string().min(10).required(),
    category: Joi.string()
      .valid('billing', 'technical', 'account', 'general', 'feature_request')
      .required(),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'critical')
      .default('medium'),
    attachments: Joi.array().items(Joi.string().uuid())
  }),

  updateTicket: Joi.object({
    status: Joi.string()
      .valid('open', 'in_progress', 'on_hold', 'closed', 'reopened')
      .optional(),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'critical')
      .optional(),
    assignedToId: Joi.string().uuid().allow(null).optional()
  }).min(1),

  createComment: Joi.object({
    content: Joi.string().min(1).required(),
    isInternal: Joi.boolean().default(false),
    attachments: Joi.array().items(Joi.string().uuid())
  }),

  updateProfile: Joi.object({
    name: Joi.string().max(255).optional(),
    phone: Joi.string()
      .pattern(/^[0-9]{10,}$/)
      .optional()
      .allow(null)
  }).min(1),

  changePassword: Joi.object({
    currentPassword: Joi.string().required(),
    newPassword: Joi.string()
      .min(8)
      .pattern(/[A-Z]/)
      .pattern(/[a-z]/)
      .pattern(/[0-9]/)
      .pattern(/[!@#$%^&*]/)
      .required()
  }),

  resetPassword: Joi.object({
    email: Joi.string().email().required()
  })
};

const validate = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      const details = error.details.map(d => ({
        field: d.path.join('.'),
        message: d.message
      }));
      return res.status(422).json({
        success: false,
        message: 'Validation failed',
        error: { code: 'VALIDATION_ERROR', details }
      });
    }

    req.validatedBody = value;
    next();
  };
};

module.exports = {
  schemas,
  validate
};
